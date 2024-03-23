using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;

namespace forma_app.Model
{
    public class SummaryQa(Answer answer)
    {
        public string Question { get; set; } = answer.Question.VarQuestion;

        public string Answer { get; set; } = answer.VarAnswer;

        public override string ToString()
        {
            return Question + ": " + Answer;
        }
    }
}
