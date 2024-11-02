namespace COB.Domain;

public abstract class DocumentBase
{
    public DocumentBase()
    {
        Id = Guid.NewGuid();
    }

    public Guid Id { get; set; }
}
