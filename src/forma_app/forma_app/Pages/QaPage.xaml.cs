using forma_app.ViewModels;

namespace forma_app.Pages;

public partial class QaPage : ContentPage
{
	public QaPage(QaViewModel qaViewModel)
	{
		InitializeComponent();
		BindingContext = qaViewModel;
	}
}