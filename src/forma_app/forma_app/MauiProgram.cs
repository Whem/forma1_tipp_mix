using CommunityToolkit.Maui;
using forma_app.Pages;
using forma_app.Services;
using forma_app.ViewModels;
using Microsoft.Extensions.Logging;
using Syncfusion.Maui.Core.Hosting;

namespace forma_app
{
    public static class MauiProgram
    {
        public static MauiApp CreateMauiApp()
        {
            Syncfusion.Licensing.SyncfusionLicenseProvider.RegisterLicense(Licenses.SYNCFUSION_KEY);
            var builder = MauiApp.CreateBuilder();
            builder
                .UseMauiApp<App>()
                .ConfigureSyncfusionCore()
                .UseMauiCommunityToolkit()
                .ConfigureFonts(fonts =>
                {
                    fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                    fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
                })
                .RegisterServices();

#if DEBUG
            builder.Logging.AddDebug();
#endif

            return builder.Build();
        }

        static void RegisterServices(this MauiAppBuilder builder)
        {
            var s = builder.Services;
            
            // Register services    
            s.AddSingleton<NavigationService>();
            s.AddSingleton<ApiService>();
            s.AddSingleton<StoreService>();
            

            // Register view models and pages
            s.AddTransient<MainViewModel>();
            s.AddTransient<MainPage>();

            
            s.AddTransient<LoginViewModel>();
            s.AddTransient<LoginPage>();

            s.AddTransient<RegisterPage>();
            s.AddTransient<RegisterViewModel>();

            s.AddTransient<QaPage>();
            s.AddTransient<QaViewModel>();

            s.AddTransient<StatisticsPage>();
            s.AddTransient<StatisticsViewModel>();

            s.AddTransient<QaSummaryPage>();
            s.AddTransient<QaSummaryViewModel>();
        }
    }
}
