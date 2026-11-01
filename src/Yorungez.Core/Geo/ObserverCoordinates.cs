namespace Yorungez.Core.Geo;

/// <summary>
/// A validated latitude/longitude pair in degrees. Values retain their supplied
/// double precision; this type does not claim a device measurement accuracy.
/// </summary>
public readonly record struct ObserverCoordinates
{
    public double Latitude { get; }

    public double Longitude { get; }

    private ObserverCoordinates(double latitude, double longitude)
    {
        Latitude = latitude;
        Longitude = longitude;
    }

    public static ObserverCoordinates Create(double latitude, double longitude)
    {
        if (!double.IsFinite(latitude) || latitude is < -90 or > 90)
        {
            throw new ArgumentOutOfRangeException(
                nameof(latitude),
                "Latitude must be finite and between -90 and 90 degrees.");
        }

        if (!double.IsFinite(longitude) || longitude is < -180 or > 180)
        {
            throw new ArgumentOutOfRangeException(
                nameof(longitude),
                "Longitude must be finite and between -180 and 180 degrees.");
        }

        return new ObserverCoordinates(latitude, longitude);
    }
}
