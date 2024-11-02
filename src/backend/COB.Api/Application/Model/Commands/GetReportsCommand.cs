using COB.Domain.Reports;
using MediatR;

namespace COB.Api.Application.Model.Commands;

public class GetReportsCommand : IRequest<List<ReportDocument>>
{
    public GetReportsCommand(double latitude,
        double longitude, 
        double radius,
        string? reportTypeFilter)
    {
        Latitude = latitude;
        Longitude = longitude;
        Radius = radius;
        ReportTypeFilter = reportTypeFilter;
    }
    
    public double Latitude { get; }

    public double Longitude { get; }

    public double Radius { get; }

    public string? ReportTypeFilter { get; }
}
