using COB.Domain.Reports;

namespace COB.Infrastructure.Repositories.Mongo;

public class ReportRepository : MongoDriverRepositoryBase<ReportDocument>, IReportRepository
{
    public ReportRepository(IOptions<MongoSettings> settings) : base(settings)
    {
    }

    public IQueryable<ReportDocument> QueryReports(double latitude, double longitude, double radius)
    {
        var reports = QueryDocuments();

        var earthRadiusKm = 6371;
        var radiusInRadians = radius / earthRadiusKm;

        var filteredReports = reports.Where(report =>
            Math.Acos(
                Math.Sin(DegreesToRadians(latitude)) * Math.Sin(DegreesToRadians(report.Latitude)) +
                Math.Cos(DegreesToRadians(latitude)) * Math.Cos(DegreesToRadians(report.Latitude)) *
                Math.Cos(DegreesToRadians(report.Longitude - longitude))
            ) <= radiusInRadians);

        return reports;
    }
    private double DegreesToRadians(double degrees)
    {
        return degrees * (Math.PI / 180);
    }
}