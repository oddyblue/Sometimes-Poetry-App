// WeatherService.swift
// Apple WeatherKit integration with IP-based location (no permission required)

import Foundation
import WeatherKit
import CoreLocation
import OSLog

private let logger = Logger(subsystem: "com.poemforthemoment", category: "Weather")

actor WeatherService {
    private var cachedWeather: WeatherCondition?
    private var cacheTimestamp: Date?
    private let cacheDuration: TimeInterval = 6 * 3600 // 6 hours

    private let weatherKitService = WeatherKit.WeatherService.shared

    // MARK: - Public API

    func getWeather() async -> WeatherCondition? {
        // Return cached if valid
        if let cached = cachedWeather,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheDuration {
            return cached
        }

        // Try to fetch fresh weather
        guard let weather = await fetchWeather() else {
            // Return stale cache if available, otherwise use seasonal fallback
            return cachedWeather ?? seasonalFallbackWeather()
        }

        cachedWeather = weather
        cacheTimestamp = Date()
        return weather
    }

    // MARK: - WeatherKit Integration

    private func fetchWeather() async -> WeatherCondition? {
        // Step 1: Get approximate location from IP (no permission needed)
        guard let coords = await getIPLocation() else {
            logger.info("IP location unavailable, using seasonal fallback")
            return seasonalFallbackWeather()
        }

        // Step 2: Fetch weather using Apple WeatherKit
        let location = CLLocation(latitude: coords.lat, longitude: coords.lon)
        return await fetchWeatherKitData(for: location)
    }

    private func fetchWeatherKitData(for location: CLLocation) async -> WeatherCondition? {
        do {
            let weather = try await weatherKitService.weather(for: location)
            let condition = mapWeatherKitCondition(weather.currentWeather.condition)
            logger.info("WeatherKit fetched: \(condition.rawValue)")
            return condition
        } catch {
            logger.error("WeatherKit error: \(error.localizedDescription)")
            return seasonalFallbackWeather()
        }
    }

    // MARK: - IP Geolocation

    private func getIPLocation() async -> (lat: Double, lon: Double)? {
        // Using ipinfo.io (HTTPS, free tier, no key required for basic usage)
        guard let url = URL(string: "https://ipinfo.io/json") else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            let json = try JSONDecoder().decode(IPInfoResponse.self, from: data)

            // Parse "lat,lon" string format
            let coords = json.loc.split(separator: ",")
            guard coords.count == 2,
                  let lat = Double(coords[0]),
                  let lon = Double(coords[1]) else {
                return nil
            }

            return (lat: lat, lon: lon)
        } catch {
            logger.error("IP location lookup failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Condition Mapping

    private func mapWeatherKitCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherCondition {
        switch condition {
        // Clear conditions
        case .clear, .mostlyClear, .hot:
            return .clear

        // Cloudy conditions
        case .cloudy, .mostlyCloudy, .partlyCloudy:
            return .cloudy

        // Rainy conditions
        case .rain, .heavyRain, .drizzle, .sunShowers, .hail:
            return .rainy

        // Snowy conditions
        case .snow, .heavySnow, .flurries, .sleet, .freezingRain,
             .freezingDrizzle, .wintryMix, .blizzard, .blowingSnow, .frigid:
            return .snowy

        // Stormy conditions
        case .thunderstorms, .tropicalStorm, .hurricane,
             .isolatedThunderstorms, .scatteredThunderstorms,
             .strongStorms, .sunFlurries:
            return .stormy

        // Foggy conditions
        case .foggy, .haze, .smoky, .breezy, .windy, .blowingDust:
            return .foggy

        // Default to clear for any unmapped conditions
        @unknown default:
            return .clear
        }
    }

    /// Returns a seasonally-appropriate weather condition when API is unavailable
    private func seasonalFallbackWeather() -> WeatherCondition {
        let season = Season.current()

        switch season {
        case .winter:
            return [.cloudy, .snowy, .clear, .cloudy, .foggy].randomElement() ?? .cloudy
        case .spring:
            return [.rainy, .clear, .cloudy, .clear, .rainy].randomElement() ?? .clear
        case .summer:
            return [.clear, .clear, .clear, .cloudy, .stormy].randomElement() ?? .clear
        case .autumn:
            return [.foggy, .rainy, .cloudy, .clear, .foggy].randomElement() ?? .cloudy
        }
    }
}

// MARK: - Response Models

private struct IPInfoResponse: Codable {
    let loc: String // Format: "lat,lon"
}
