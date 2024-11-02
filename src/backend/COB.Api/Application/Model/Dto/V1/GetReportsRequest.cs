using Swashbuckle.AspNetCore.Annotations;

namespace COB.Api.Application.Model.Dto.V1;

public class GetReportsRequest
{
    [FromQuery(Name = "latitude")]
    [SwaggerSchema("The latitude of the center of the search area. Required.", Nullable = false)]
    public double Latitude { get; set; }

    [FromQuery(Name = "longitude")]
    [SwaggerSchema("The longitude of the center of the search area. Required.", Nullable = false)]
    public double Longitude { get; set; }

    [FromQuery(Name = "radius")]
    [SwaggerSchema("The radius of the search area in meters. Required.", Nullable = false)]
    public double Radius { get; set; }

    [FromQuery(Name = "report_type_filter")]
    [SwaggerSchema("The type of report to filter by. Do not specify to not filter.", Nullable = true)]
    public string? ReportTypeFilter { get; set; }
}
