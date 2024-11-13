using COB.Domain.Reports;
using MongoDB.Bson.Serialization;

namespace COB.Infrastructure.Repositories.Mongo.Mapper;

public class ReportMongoMapper : IMongoMapper
{
    public void Configure()
    {
        BsonClassMap.RegisterClassMap<ReportDocument>(cm =>
        {
            cm.AutoMap();
            cm.SetIgnoreExtraElements(true);
        });
    }
}
