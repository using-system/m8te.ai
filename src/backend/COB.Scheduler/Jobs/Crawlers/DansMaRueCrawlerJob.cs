using COB.Domain.Reports;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Web;

namespace COB.Scheduler.Jobs.Crawlers;

public class DansMaRueCrawlerJob(IServiceScopeFactory serviceScopeFactory,
    IHttpClientFactory httpClientFactory,
    ILogger<DansMaRueCrawlerJob> logger)
    : CrawlerJobBase(serviceScopeFactory, logger)
{
    protected override string CronExpression => "0 3 * * *"; //3 AM every day

    protected override string ExternalIdPrefix => "dmr";

    protected override ReportSource Source => new ReportSource()
    {
        Copyright = "Ville de Paris",
        Name = "DansMaRue",
        Url = new Uri("https://www.paris.fr/dossiers/l-application-dansmarue-65")
    };

    protected async override Task ExecuteAsync(IServiceScope scope)
    {
        var reportDomainService = scope.ServiceProvider.GetRequiredService<ReportDomainService>();

        var httpClient = httpClientFactory.CreateClient();

        await Crawl(reportDomainService, 
            httpClient, 
            "Voirie et espace public",
            "Aménagements cyclables : Itinéraire cyclable interrompu",
            ReportType.Dangerous);

        await Crawl(reportDomainService,
           httpClient,
           "Voirie et espace public",
           "Aménagements cyclables : Affaissement, trou, bosse, pavé arraché",
           ReportType.Degradation);

        await Crawl(reportDomainService,
          httpClient,
          "Voirie et espace public",
          "Aménagements cyclables : Obstacle sur la piste (bordure descellée)",
          ReportType.Dangerous);

        await Crawl(reportDomainService,
            httpClient,
            "Voirie et espace public",
            "Marquage au sol  effacé  : Bande cyclable, logos vélo et flèches",
            ReportType.Signaling);

        await Crawl(reportDomainService,
            httpClient,
            "Autos, motos, vélos, trottinettes...",
            "Automobile ou autre véhicule motorisé en stationnement gênant",
            ReportType.Obstructing);

        await Crawl(reportDomainService,
            httpClient,
            "Éclairage / Électricité",
            "Éclairage public éteint la nuit",
            ReportType.Lighting);
    }

    private async Task Crawl(ReportDomainService reportDomainService,
        HttpClient httpClient,
        string type, 
        string soustype,
        ReportType reportType)
    {
        int limit = 100;
        int offset = 0;
        var description = soustype;
        type = HttpUtility.UrlEncode(type);
        soustype = HttpUtility.UrlEncode(soustype);

        while(true)
        {
            var apiUrl = $"https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/dans-ma-rue/records?limit={limit}&offset={offset}&refine=type%3A%22{type}%22&refine=soustype%3A%22{soustype}%22";

            var response = await httpClient.GetAsync(apiUrl);
            response.EnsureSuccessStatusCode();

            if (!response.IsSuccessStatusCode)
                break;

            var content = await response.Content.ReadAsStringAsync();
            JsonObject? responseJson = JsonSerializer.Deserialize<JsonObject>(content);

            if (responseJson != null
                && responseJson["results"] != null)
            {
                var results = responseJson["results"] as JsonArray;

                if(results!.Count == 0)
                    break;  

                foreach (var result in results!)
                {
                    if (result == null)
                        continue;

                    var id = result["numero"]!.GetValue<int>();
                    var longitude = result["geo_point_2d"]!["lon"]!.GetValue<double>();
                    var latitude = result["geo_point_2d"]!["lat"]!.GetValue<double>();
                    var date = result["datedecl"]!.GetValue<DateTimeOffset>();

                    await reportDomainService.CreateOrUpdateReportAsync($"{ExternalIdPrefix}_{id}",
                        latitude,
                        longitude,
                        ReportType.Signaling,
                        description,
                        status: ReportStatus.Resolved,
                        source: Source);
                }
            }

            offset += limit;
        }

    }
}
