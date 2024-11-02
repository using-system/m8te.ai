namespace COB.Domain;

public interface IDocumentRepository<TDocument> : IRepository
    where TDocument : DocumentBase
{
    public IQueryable<TDocument> QueryDocuments();

    public Task<TDocument> GetDocumentByIdAsync(Guid id);

    public Task CreateDocumentAsync(TDocument document);

    public Task UpdateDocumentAsync(Guid id, TDocument documentToUpdate);

    public Task DeleteDocumentAsync(Guid id);
}
