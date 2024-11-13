using COB.Api.Application.Model.Commands;
using COB.Domain.Reports;
using MediatR;

namespace COB.Api.Application.Handlers.Commands;

public class GetReportsCommandHandler(ReportDomainService reportDomainService) : IRequestHandler<GetReportsCommand, List<ReportDocument>>
{
    public async Task<List<ReportDocument>> Handle(GetReportsCommand request, 
        CancellationToken cancellationToken)
    {
        ReportType? reportTypeFilter =  Enum.TryParse<ReportType>(request.ReportTypeFilter, out ReportType result) 
            ? result : null;

        return await reportDomainService.SearchReportsAsync(request.Latitude,
            request.Longitude,
            request.Radius,
            reportTypeFilter);
    }
}
