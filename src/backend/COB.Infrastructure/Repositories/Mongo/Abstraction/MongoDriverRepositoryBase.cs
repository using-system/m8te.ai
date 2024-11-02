using MongoDB.Driver;

namespace COB.Infrastructure.Repositories.Mongo;

public abstract class MongoDriverRepositoryBase<TDocument> : IDocumentRepository<TDocument>
    where TDocument : DocumentBase
{
    private readonly IMongoCollection<TDocument> _documentCollection;

    public MongoDriverRepositoryBase(IOptions<MongoSettings> settings)
    {
        var client = new MongoClient(settings.Value.ConnectionString);
        var database = client.GetDatabase(settings.Value.DatabaseName);
        _documentCollection = database.GetCollection<TDocument>(GetType().Name);
    }

    public async Task<TDocument> GetDocumentByIdAsync(Guid id)
    {
        return await _documentCollection
            .Find(document => document.Id == id)
            .FirstOrDefaultAsync();
    }

    public IQueryable<TDocument> QueryDocuments()
    {
        return _documentCollection.AsQueryable();
    }

    public async Task CreateDocumentAsync(TDocument document)
    {
        await _documentCollection.InsertOneAsync(document);
    }

    public async Task UpdateDocumentAsync(Guid id, TDocument documentToUpdate)
    {
        await _documentCollection.ReplaceOneAsync(document => document.Id == id, documentToUpdate);
    }

    public async Task DeleteDocumentAsync(Guid id)
    {
        await _documentCollection.DeleteOneAsync(document => document.Id == id);
    }
}
