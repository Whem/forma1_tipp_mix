using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CommunityToolkit.Maui.Alerts;
using System.Windows.Input;
using forma_app.Model;
using forma_app.Services;
using CommunityToolkit.Mvvm.Input;

namespace forma_app.ViewModels
{
    public class FillResultViewModel : BaseViewModel
    {
        private Race? _selectedRace;
        public ApiService ApiService { get; }
        public NavigationService NavigationService { get; }

        private int _currentIndex = 0;
        private string? _currentQuestion;
        private string? _currentAnswer;
        private bool _isNumber = false;
        private bool _visibleClosestNumberWin = false;
        private Pilot? _selectedPilot;
        private int? _selectedNumber;
        private ObservableCollection<Pilot> _pilots = new ObservableCollection<Pilot>();
        private ObservableCollection<Question> _questions = new ObservableCollection<Question>();
        private bool _visibleCombobox;
        private bool _isRunning;
        private ObservableCollection<string> _logs = new ObservableCollection<string>();
        private ObservableCollection<Race>? _races;


        public int CurrentIndex
        {
            get => _currentIndex;
            set
            {
                _currentIndex = value;

                OnPropertyChanged();
                CurrentQuestion = Questions[_currentIndex].VarQuestion;

                if (MaxIndex <= _currentIndex)
                {
                    MaxIndex = _currentIndex;
                }

                // Hide answer when moving to a new question
            }
        }

        public string? CurrentQuestion
        {
            get => _currentQuestion;
            set
            {
                _currentQuestion = value;
                OnPropertyChanged();
            }
        }

        public string? CurrentAnswer
        {
            get => _currentAnswer;
            set
            {
                _currentAnswer = value;
                OnPropertyChanged();
            }
        }

        public bool VisibleNumberUpDown
        {
            get => _isNumber;
            set => SetProperty(ref _isNumber, value);
        }

        public bool VisibleCombobox
        {
            get => _visibleCombobox;
            set => SetProperty(ref _visibleCombobox, value);
        }

        public bool VisibleClosestNumberWin
        {
            get => _visibleClosestNumberWin;
            set => SetProperty(ref _visibleClosestNumberWin, value);
        }

        public ObservableCollection<Question> Questions
        {
            get => _questions;
            set
            {
                if (SetProperty(ref _questions, value))
                {
                    OnPropertyChanged(nameof(NextQuestionCommand));
                }
            }
        }

        public ObservableCollection<Pilot> Pilots
        {
            get => _pilots;
            set => SetProperty(ref _pilots, value);
        }

        public Pilot? SelectedPilot
        {
            get => _selectedPilot;
            set => SetProperty(ref _selectedPilot, value);
        }

        public int? SelectedNumber
        {
            get => _selectedNumber;
            set => SetProperty(ref _selectedNumber, value);
        }

        public int MaxIndex { get; set; }

        public ObservableCollection<Race>? Races
        {
            get => _races;
            set => SetProperty(ref _races, value);
        }

        public Race? SelectedRace
        {
            get => _selectedRace;
            set => SetProperty(ref _selectedRace, value);
        }

        public FillResultViewModel(ApiService apiService, NavigationService navigationService)
        {
            ApiService = apiService;
            NavigationService = navigationService;

            Task.Run(async () =>
            {
                try
                {
                    IsBusy = true;
                    await Task.Delay(2000);
                    List<Race>? races = await ApiService.DataApi.DataRacesListAsync();

                    Races = new ObservableCollection<Race>();

                    foreach (Race race in races)
                    {
                        MainThread.BeginInvokeOnMainThread(() => { Races.Add(race); });
                    }

                    await LoadQuestions();
                }
                catch (Exception e)
                {
                    MainThread.BeginInvokeOnMainThread(async () =>
                    {
                        await Toast.Make(e.Message).Show();
                    });
                    
                }
                finally
                {
                    IsBusy = false;
                }
                
            });
        }

        private async Task LoadQuestions()
        {
            

            var pilots = await ApiService.DataApi.DataPilotsListAsync(1);
            var questions = await ApiService.TipsApi.TipsQuestionsListAsync(1);
            MainThread.BeginInvokeOnMainThread(() =>
            {
                Pilots.Clear();
                foreach (var pilot in pilots)
                {
                    Pilots.Add(new Pilot(pilot.Id, pilot.Name));
                }

                Questions.Clear();
                foreach (var question in questions)
                {
                    Questions.Add(question);
                }

                GetCurrentAnswer();
            });
        }

       
        public void GetCurrentAnswer()
        {
            try
            {
               
                if (SelectedRace != null && MaxIndex > CurrentIndex)
                {
                    var currentAnswer = ApiService.TipsApi.TipsAnswersList(SelectedRace.Id, Questions[CurrentIndex].Id);

                    CurrentAnswer = currentAnswer.Count > 0 ? currentAnswer[0].VarAnswer : string.Empty;
                }

                CurrentQuestion = Questions[CurrentIndex].VarQuestion;

                VisibleNumberUpDown = Questions[CurrentIndex].IsNumber;

                VisibleCombobox = !VisibleNumberUpDown;

                VisibleClosestNumberWin = Questions[CurrentIndex].ClosestNumber;

                if (VisibleNumberUpDown)
                {
                    SelectedNumber = null;
                }
                else
                {
                    SelectedPilot = null;
                }
            }
            catch (Exception e)
            {
                MainThread.BeginInvokeOnMainThread(async () =>
                {
                   await Toast.Make(e.Message).Show();
                });
                
            }
           

        }

        public ICommand NextQuestionCommand => new Command(async () =>
        {

            try
            {
                IsBusy = true;
                await Task.Delay(2000);

                string answer;

                if (VisibleNumberUpDown)
                {
                    answer = SelectedNumber?.ToString() ?? string.Empty;
                }
                else
                {
                    answer = SelectedPilot?.Name ?? string.Empty;
                }

                if (string.IsNullOrEmpty(answer))
                {
                    MainThread.BeginInvokeOnMainThread(async () =>
                    {
                        await Toast.Make("Please select an answer").Show();
                    });
                    
                    return;
                }



                if (SelectedRace != null)
                    await ApiService.TipsApi.TipsRaceResultsCreateAsync(new PostAnswerRequest(SelectedRace.Id,
                        Questions[CurrentIndex].Id, answer));

                if (CurrentIndex < Questions.Count - 1) CurrentIndex++;
                else
                {
                    await NavigationService.OnNavigateAsync(NavigationService.NavigationPageEnum.Compare, false);
                }

                GetCurrentAnswer();
            }
            catch (Exception e)
            {
                MainThread.BeginInvokeOnMainThread(async () =>
                {
                    await Toast.Make(e.Message).Show();
                });
               
            }
            finally
            {
                IsBusy = false;
            }

            


        });

        public RelayCommand BackCommand => new RelayCommand(async () => await NavigationService.OnNavigateAsync(NavigationService.NavigationPageEnum.Main, true).ConfigureAwait(false));
    }
}
