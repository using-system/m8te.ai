namespace COB.Domain.Reports;

public class ReportSource
{
    public ReportSource()
    {
        Name = "co.bike";
        Copyright = string.Empty;
        Url = new Uri("https://co.bike");
    }

    public string Name { get; set; }

    public string Copyright { get; set; }

    public Uri Url { get; set; }
}
