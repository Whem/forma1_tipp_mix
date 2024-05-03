using forma_app.Pages;

namespace forma_app
{
    public partial class AppShell : Shell
    {
        public AppShell()
        {
            InitializeComponent();
            Routing.RegisterRoute(nameof(LoginPage), typeof(LoginPage));
            Routing.RegisterRoute(nameof(RegisterPage), typeof(RegisterPage));
            Routing.RegisterRoute(nameof(MainPage), typeof(MainPage));
            Routing.RegisterRoute(nameof(QaPage), typeof(QaPage));
            Routing.RegisterRoute(nameof(StatisticsPage), typeof(StatisticsPage));
            Routing.RegisterRoute(nameof(QaSummaryPage), typeof(QaSummaryPage));
            Routing.RegisterRoute(nameof(FillResultPage), typeof(FillResultPage));
            Routing.RegisterRoute(nameof(ComparePage), typeof(ComparePage));


        }

        private void AppShell_OnNavigating(object sender, ShellNavigatingEventArgs e)
        {
            base.OnNavigating(e);
            // Cancel any back navigation.
            if (e.Source == ShellNavigationSource.Pop)
            {
                e.Cancel();
            }
        }
    }
}
