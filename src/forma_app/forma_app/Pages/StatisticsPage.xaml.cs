using forma_app.ViewModels;

namespace forma_app.Pages;

public partial class StatisticsPage : ContentPage
{
	public StatisticsPage(StatisticsViewModel statisticsViewModel)
	{
		InitializeComponent();
		BindingContext = statisticsViewModel;
	}
}