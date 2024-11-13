using System;

namespace COB.Domain.Reports;

public class ReportDomainService(IReportRepository reportRepository) : IDomainService
{
    public Task<List<ReportDocument>> SearchReportsAsync(double latitude, 
        double longitude, 
        double radius,
        ReportType? reportType)
    {
        var query = reportRepository.QueryReports(latitude, longitude, radius);

        if(reportType.HasValue)
        {
            query = query.Where(report => report.Type == reportType.Value);
        }

        return Task.FromResult(query
            .Where(reportRepository => reportRepository.IsApproved)
            .OrderByDescending(report => report.Timespan)
            .Take(100)
            .ToList());
    }

    public async Task<ReportDocument> CreateOrUpdateReportAsync(string externalId,
        double latitude,
        double longitude,
        ReportType reportType,
        string description,
        ReportStatus status = ReportStatus.New,
        ReportSource? source = null,
        DateTimeOffset? date = null,
        Guid? accountId = null)
    {
        var report = reportRepository.QueryDocuments()
            .Where(report => report.ExternalId == externalId)
            .SingleOrDefault();

        if (report == null)
        {
            report = new ReportDocument
            {
                Latitude = latitude,
                Longitude = longitude,
                Type = reportType,
                Description = description,
                ExternalId = externalId,
                AccountId = accountId,
                Status = status,
                IsApproved = true,
                CanBeResolved = true,
                Source = source ?? new ReportSource(),
                Timespan = date.HasValue ? date.Value.ToUnixTimeMilliseconds() : DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
            };

            await reportRepository.CreateDocumentAsync(report);
        }
        else
        {
            report.Description = description;
            report.Longitude = longitude;
            report.Latitude = latitude;
            report.Status = status;

            await reportRepository.UpdateDocumentAsync(report.Id, report);
        }

        return report;
    }
}
