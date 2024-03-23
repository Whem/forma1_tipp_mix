using forma_app.ViewModels;

namespace forma_app.Pages;

public partial class QaSummaryPage : ContentPage
{
	public QaSummaryPage(QaSummaryViewModel qaSummaryViewModel)
	{
		InitializeComponent();
		BindingContext = qaSummaryViewModel;
	}
}