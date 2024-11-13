using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.IdGenerators;

namespace COB.Infrastructure.Repositories.Mongo.Mapper;

public class DocumentBaseMapping : IMongoMapper
{
    public void Configure()
    {
        if (!BsonClassMap.IsClassMapRegistered(typeof(DocumentBase)))
        {
            BsonClassMap.RegisterClassMap<DocumentBase>(cm =>
            {
                cm.AutoMap();
                cm.MapIdMember(c => c.Id)
                  .SetIdGenerator(GuidGenerator.Instance)
                  .SetSerializer(new MongoDB.Bson.Serialization.Serializers.GuidSerializer(GuidRepresentation.Standard));
            });
        }
    }
}
