using COB.Api.Application.Model.Commands;
using COB.Api.Application.Model.Dto.V1;
using COB.Domain.Reports;
using MediatR;
using System.Net;

namespace COB.Api.Controllers.V1;

[ApiVersion("1.0")]
[Route("v{version:apiVersion}/[controller]")]
[ApiController]
public class ReportsController(IMediator mediator) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(List<GetReportsResponse.GetReportsResponseItem>), (int)HttpStatusCode.OK)]
    [ProducesResponseType((int)HttpStatusCode.TooManyRequests)]
    [ProducesResponseType((int)HttpStatusCode.InternalServerError)]
    public async Task<IActionResult> GetReports(GetReportsRequest request)
    {
        var reports = await mediator.Send(
            new GetReportsCommand(request.Latitude, 
            request.Longitude, 
            request.Radius, 
            request.ReportTypeFilter));

        return Ok(new GetReportsResponse(reports));
    }

    [HttpGet("{report_id}")]
    [ProducesResponseType(typeof(GetReportByIdResponse), (int)HttpStatusCode.OK)]
    [ProducesResponseType((int)HttpStatusCode.NotFound)]
    [ProducesResponseType((int)HttpStatusCode.TooManyRequests)]
    [ProducesResponseType((int)HttpStatusCode.InternalServerError)]
    public async Task<IActionResult> GetReportById(GetReportByIdRequest request)
    {
        var report = new ReportDocument();

        if (report == null)
        {
            return NotFound();
        }

        return Ok(report);
    }

}
