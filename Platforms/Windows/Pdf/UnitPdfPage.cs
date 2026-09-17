using Baguettepic.Models;

namespace Baguettepic.WindowsPdf;

sealed record UnitPdfPage(
    BaseProfile Profile,
    IReadOnlyList<RuleListItem> Skills,
    IReadOnlyList<RuleListItem> PsychicPowers);
