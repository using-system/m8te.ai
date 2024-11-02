using Swashbuckle.AspNetCore.Annotations;

namespace COB.Api.Application.Model.Dto.V1;

public class GetReportByIdRequest
{
    [FromRoute(Name = "report_id")]
    [SwaggerSchema("The unique identifier for the report.")]
    public Guid ReportId { get; set; }
}
