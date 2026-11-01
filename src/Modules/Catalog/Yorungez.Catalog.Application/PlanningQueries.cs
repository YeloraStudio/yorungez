using MediatR;
using Yorungez.Application;
using Yorungez.Catalog.Domain;
namespace Yorungez.Catalog.Application;

public interface IPlanningCatalog {
    CalendarMonth ReadMonth(int year, int month);
    LocatedPlace[] FindPlaces(string? query, double? latitude, double? longitude);
}
public sealed record GetCalendarMonthQuery(int Year,int Month):IQuery<CalendarMonth>;
public sealed class GetCalendarMonthHandler(IPlanningCatalog catalog):IRequestHandler<GetCalendarMonthQuery,CalendarMonth>{
    public Task<CalendarMonth> Handle(GetCalendarMonthQuery q,CancellationToken ct){ct.ThrowIfCancellationRequested();
        if(q.Year is <2000 or >2035 || q.Month is <1 or >12)throw new AppFailure("Calendar.InvalidMonth",FailureKind.Validation);
        return Task.FromResult(catalog.ReadMonth(q.Year,q.Month));}
}
public sealed record FindPlacesQuery(string? Query,double? Latitude,double? Longitude):IQuery<LocatedPlace[]>;
public sealed class FindPlacesHandler(IPlanningCatalog catalog):IRequestHandler<FindPlacesQuery,LocatedPlace[]>{
    public Task<LocatedPlace[]> Handle(FindPlacesQuery q,CancellationToken ct){ct.ThrowIfCancellationRequested();
        if(q.Query is not null ? q.Query.Trim().Length is <2 or >120 : q.Latitude is null || q.Longitude is null || !double.IsFinite(q.Latitude.Value) || !double.IsFinite(q.Longitude.Value) || Math.Abs(q.Latitude.Value)>90 || Math.Abs(q.Longitude.Value)>180)
            throw new AppFailure("Place.InvalidInput",FailureKind.Validation);
        return Task.FromResult(catalog.FindPlaces(q.Query,q.Latitude,q.Longitude));}
}
