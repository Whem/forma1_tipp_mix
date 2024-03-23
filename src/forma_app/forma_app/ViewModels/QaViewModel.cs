using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;
using CommunityToolkit.Maui.Alerts;
using CommunityToolkit.Mvvm.Input;
using forma_app.Model;
using forma_app.Services;

namespace forma_app.ViewModels
{
    public class QaViewModel : BaseViewModel
    {
        private Race? _currentRace;
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

        public Race? CurrentRace
        {
            get => _currentRace;
            set => SetProperty(ref _currentRace, value);
        }

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
                    OnPropertyChanged(nameof(PreviousQuestionCommand));
                }
            }
        }

        public ObservableCollection<Pilot> Pilots
        {
            get => _pilots;
            set
            {
                if (SetProperty(ref _pilots, value)) OnPropertyChanged(nameof(PreviousQuestionCommand));
            }
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

        public QaViewModel(ApiService apiService, NavigationService navigationService)
        {
            ApiService = apiService;
            NavigationService = navigationService;

            Task.Run(async () => await LoadQuestions());
        }

        public int MaxIndex { get; set; }

        private async Task LoadQuestions()
        {
            CurrentRace = await ApiService.DataApi.DataCurrentRaceRetrieveAsync();
            
            var pilots = await ApiService.DataApi.DataPilotsListAsync(CurrentRace.Id);
            var questions = await ApiService.TipsApi.TipsQuestionsListAsync(CurrentRace.Id);
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

        public bool IsRunning
        {
            get => _isRunning;
            set => SetProperty(ref _isRunning, value);
        }

        public void GetCurrentAnswer()
        {
            try
            {
                IsRunning = true;
                if (CurrentRace != null && MaxIndex > CurrentIndex)
                {
                    var currentAnswer = ApiService.TipsApi.TipsAnswersList(CurrentRace.Id, Questions[CurrentIndex].Id);

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
                Toast.Make(e.Message).Show();
            }
            finally
            {
                IsRunning = false;
            }
           
        }

        public ICommand NextQuestionCommand => new Command(async () =>
        {



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
                await Toast.Make("Please select an answer").Show();
                return;
            }

            Logs.Add("Question: " + Questions[CurrentIndex].VarQuestion + " Answer: " + answer);

            if (CurrentRace != null)
                await ApiService.TipsApi.TipsAnswersCreateAsync(new PostAnswerRequest(CurrentRace.Id,
                    Questions[CurrentIndex].Id, answer));

            if (CurrentIndex < Questions.Count - 1) CurrentIndex++;
            else
            {
                await NavigationService.OnNavigateAsync(NavigationService.NavigationPageEnum.QaSummary, false);
            }

            GetCurrentAnswer();

            
        });

        public ObservableCollection<string> Logs
        {
            get => _logs;
            set => SetProperty(ref _logs, value);
        }

        public RelayCommand BackCommand => new RelayCommand(async () => await NavigationService.OnNavigateAsync(NavigationService.NavigationPageEnum.Main, true).ConfigureAwait(false));

        public ICommand PreviousQuestionCommand => new Command(() =>
        {
            

            if (CurrentIndex > 0) CurrentIndex--;

            GetCurrentAnswer();


        });

  
    }
}
