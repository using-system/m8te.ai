using COB.Domain;
using COB.Infrastructure.Repositories.Mongo;
using Microsoft.Extensions.DependencyInjection;

namespace COB.Application.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddCobServices(this IServiceCollection services)
    {
        services.AddDomainServices();
        services.AddRepositories();
        services.AddMongoInfrastructure();

        return services;
    }

    private static IServiceCollection AddDomainServices(this IServiceCollection services)
    {
        var domainAssembly = typeof(IDomainService).Assembly;
        var domainServices = domainAssembly.GetTypes()
            .Where(t => t.IsClass && !t.IsAbstract && t.GetInterfaces().Any(i => i == typeof(IDomainService)))
            .ToList();

        domainServices.ForEach(domainServices =>
        {
            services.AddScoped(domainServices);
        });

        return services;
    }

    private static IServiceCollection AddRepositories(this IServiceCollection services)
    {
        var infraAssembly = typeof(MongoDriverRepositoryBase<>).Assembly;
        var repositories = infraAssembly.GetTypes()
            .Where(t => t.IsClass && !t.IsAbstract && typeof(IRepository).IsAssignableFrom(t))
            .ToList();

        repositories.ForEach(repository =>
        {
            var @interface = repository.GetInterfaces()
            .First(i => !i.IsGenericType 
            && i != typeof(IRepository)
            && typeof(IRepository).IsAssignableFrom(i));

            services.AddScoped(@interface, repository);
        });

        return services;
    }

    private static IServiceCollection AddMongoInfrastructure(this IServiceCollection services)
    {
        var assembly = typeof(IMongoMapper).Assembly;

        var mappingTypes = assembly.GetTypes()
            .Where(t => typeof(IMongoMapper).IsAssignableFrom(t) && !t.IsInterface && !t.IsAbstract);

        foreach (var mappingType in mappingTypes)
        {
            services.AddSingleton(typeof(IMongoMapper), mappingType);
        }

        return services;
    }
}
