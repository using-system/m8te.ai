using COB.Domain.Reports;

namespace COB.Api.Application.Model.Dto.V1;

public class GetReportsResponse : List<GetReportsResponse.GetReportsResponseItem>
{
    public GetReportsResponse(List<ReportDocument> documents)
    {
        documents.ForEach(document =>
        {
            Add(new GetReportsResponseItem
            {
                Type = document.Type.ToString(),
                Longitude = document.Longitude,
                Latitude = document.Latitude
            });
        });
    }

    public class GetReportsResponseItem
    {
        public GetReportsResponseItem()
        {
            Type = string.Empty;
        }

        public string Type { get; set; }

        public double Longitude { get; set; }

        public double Latitude { get; set; }
    }
}
