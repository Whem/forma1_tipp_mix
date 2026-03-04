import argparse
import logging
import signal
import sys
import threading

import firebase_admin
from firebase_admin import credentials

import config


def setup_logging():
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler("f1tipp.log", encoding="utf-8"),
        ],
    )


def init_firebase():
    cred = credentials.Certificate(config.SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred)
    logging.getLogger(__name__).info("Firebase Admin initialized")


def run_notifications(notification_service):
    notification_service.start()


def run_results(worker):
    worker.start()


def run_live(relay):
    relay.start()


def main():
    parser = argparse.ArgumentParser(description="F1 Tipp Mix VPS Server")
    parser.add_argument("--notifications", action="store_true", help="Run notification service")
    parser.add_argument("--results", action="store_true", help="Run race result worker")
    parser.add_argument("--live", action="store_true", help="Run live race relay")
    parser.add_argument("--all", action="store_true", help="Run all services")
    args = parser.parse_args()

    if not any([args.notifications, args.results, args.live, args.all]):
        parser.print_help()
        sys.exit(1)

    setup_logging()
    logger = logging.getLogger(__name__)
    init_firebase()

    threads: list[threading.Thread] = []
    shutdown_event = threading.Event()

    from notification_service import NotificationService
    from race_result_worker import RaceResultWorker
    from live_race_relay import LiveRaceRelay
    from file_server import start_file_server

    notification_svc = None

    logger.info("Starting file server for avatar uploads...")
    start_file_server()

    if args.notifications or args.all:
        notification_svc = NotificationService()
        t = threading.Thread(target=run_notifications, args=(notification_svc,), daemon=True, name="notifications")
        threads.append(t)
        logger.info("Notification service enabled")

    if args.results or args.all:
        worker = RaceResultWorker(notification_service=notification_svc)
        t = threading.Thread(target=run_results, args=(worker,), daemon=True, name="results")
        threads.append(t)
        logger.info("Race result worker enabled")

    if args.live or args.all:
        relay = LiveRaceRelay()
        t = threading.Thread(target=run_live, args=(relay,), daemon=True, name="live")
        threads.append(t)
        logger.info("Live race relay enabled")

    def signal_handler(signum, frame):
        logger.info("Shutdown signal received (%s)", signal.Signals(signum).name)
        shutdown_event.set()

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    for t in threads:
        t.start()

    logger.info("All services started (%d threads)", len(threads))

    try:
        shutdown_event.wait()
    except KeyboardInterrupt:
        pass

    logger.info("Shutting down...")
    sys.exit(0)


if __name__ == "__main__":
    main()
