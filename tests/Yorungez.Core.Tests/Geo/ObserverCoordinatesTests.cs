using Yorungez.Core.Geo;

namespace Yorungez.Core.Tests.Geo;

public sealed class ObserverCoordinatesTests
{
    [Theory]
    [InlineData(0d, 0d)]
    [InlineData(-90d, -180d)]
    [InlineData(90d, 180d)]
    [InlineData(-90d, 180d)]
    [InlineData(90d, -180d)]
    [InlineData(-12.3456789012345d, 67.890123456789d)]
    public void Create_preserves_valid_coordinate_values(double latitude, double longitude)
    {
        var coordinates = ObserverCoordinates.Create(latitude, longitude);

        Assert.Equal(latitude, coordinates.Latitude);
        Assert.Equal(longitude, coordinates.Longitude);
    }

    [Theory]
    [InlineData(-90.0000000001d)]
    [InlineData(90.0000000001d)]
    [InlineData(double.NaN)]
    [InlineData(double.PositiveInfinity)]
    [InlineData(double.NegativeInfinity)]
    public void Create_rejects_invalid_latitude_without_clamping(double latitude)
    {
        Assert.Throws<ArgumentOutOfRangeException>(
            "latitude", () => ObserverCoordinates.Create(latitude, 0d));
    }

    [Theory]
    [InlineData(-180.0000000001d)]
    [InlineData(180.0000000001d)]
    [InlineData(double.NaN)]
    [InlineData(double.PositiveInfinity)]
    [InlineData(double.NegativeInfinity)]
    public void Create_rejects_invalid_longitude_without_wrapping(double longitude)
    {
        Assert.Throws<ArgumentOutOfRangeException>(
            "longitude", () => ObserverCoordinates.Create(0d, longitude));
    }

    [Fact]
    public void Create_does_not_round_or_swap_supplied_precision()
    {
        const double latitude = 12.345678901234567d;
        const double longitude = -98.76543210987654d;

        var coordinates = ObserverCoordinates.Create(latitude, longitude);

        Assert.Equal(BitConverter.DoubleToInt64Bits(latitude),
            BitConverter.DoubleToInt64Bits(coordinates.Latitude));
        Assert.Equal(BitConverter.DoubleToInt64Bits(longitude),
            BitConverter.DoubleToInt64Bits(coordinates.Longitude));
    }

    [Fact]
    public void Zero_coordinates_are_a_valid_location_including_the_default_value()
    {
        var origin = ObserverCoordinates.Create(0d, 0d);

        Assert.Equal(default(ObserverCoordinates), origin);
        Assert.Equal(0d, origin.Latitude);
        Assert.Equal(0d, origin.Longitude);
    }
}
