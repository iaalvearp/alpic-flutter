export interface WeatherMeasurement {
  value: number;
  unit: string;
}

export interface ImageWeatherModel {
  imageId: string;
  provider: 'open-meteo';
  coordinates: {
    latitude: number;
    longitude: number;
  };
  providerCoordinates: {
    latitude: number;
    longitude: number;
  };
  timezone: string;
  observedAt: string;
  current: {
    temperature: WeatherMeasurement;
    apparentTemperature: WeatherMeasurement;
    relativeHumidity: WeatherMeasurement;
    precipitation: WeatherMeasurement;
    windSpeed: WeatherMeasurement;
    weatherCode: number;
    isDay: boolean;
  };
}
