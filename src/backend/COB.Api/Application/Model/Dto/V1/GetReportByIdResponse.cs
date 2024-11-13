namespace COB.Api.Application.Model.Dto.V1;

public class GetReportByIdResponse
{
    public GetReportByIdResponse()
    {
        Description = string.Empty;
        Type = string.Empty;
    }

    public string Description { get; set; }

    public string Type { get; set; }

    public double Longitude { get; set; }

    public double Latitude { get; set; }
}
