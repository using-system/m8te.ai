using COB.Infrastructure.Repositories.Mongo;
using Microsoft.Extensions.DependencyInjection;

namespace COB.Application.Extensions;

public static class ServiceProviderExtensions
{
    public static IServiceProvider UseCobServices(this IServiceProvider serviceProvider)
    {
        serviceProvider.UseMongoInfrastructure();

        return serviceProvider;
    }

    private static IServiceProvider UseMongoInfrastructure(this IServiceProvider serviceProvider)
    {
        var mappings = serviceProvider.GetServices<IMongoMapper>();

        foreach (var mapping in mappings)
        {
            mapping.Configure();
        }

        return serviceProvider;
    }

}
