namespace COB.Domain.Reports;

public class ReportDocument : DocumentBase
{
    public ReportDocument()
    {
        ExternalId = string.Empty;
        Description = string.Empty;
        Source = new ReportSource();
    }

    public string ExternalId { get; set; }

    public Guid? AccountId { get; set; }

    public string Description { get; set; }

    public double Longitude { get; set; }

    public double Latitude { get; set; }

    public ReportType Type { get; set; }

    public ReportStatus Status { get; set; }

    public bool IsApproved { get; set; }

    public bool CanBeResolved { get; set; }

    public ReportSource Source { get; set; }

    public long Timespan { get; set; }
}
