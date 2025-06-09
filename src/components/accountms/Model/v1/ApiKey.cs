namespace accountms.Model.v1;

public record ApiKey(
    string Name,
    string ClientId,
    string ClientSecret,
    DateTimeOffset? Expiration
);
