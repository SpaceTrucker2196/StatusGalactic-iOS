import Foundation

/// A single solar imagery feed. URL points at the "latest" frame for the
/// given instrument + channel, refreshed by the provider every few minutes.
struct SunImageSource: Identifiable, Hashable {
    var id: String { url.absoluteString }
    let url: URL
    let label: String        // short title shown under the tile
    let caption: String      // human-readable description of what we're seeing
    let provider: String     // attribution
}

/// Static catalog of current-frame sun imagery. Adjust ordering to taste —
/// the first entries appear leftmost in the scroll.
enum SunImageCatalog {

    // SDO (Solar Dynamics Observatory) — NASA, 512px crops of the latest frame.
    private static let sdoBase = "https://sdo.gsfc.nasa.gov/assets/img/latest"

    // GOES SUVI (Solar Ultraviolet Imager) — NOAA SWPC, latest frame.
    private static let suviBase = "https://services.swpc.noaa.gov/images/animations/suvi/primary"

    // SOHO LASCO coronagraphs — NASA/ESA, served via NOAA SWPC.
    private static let lascoBase = "https://services.swpc.noaa.gov/images/animations"

    static let all: [SunImageSource] = [
        .init(
            url: URL(string: "\(sdoBase)/latest_512_HMIIF.jpg")!,
            label: "Visible (HMI)",
            caption: "Sunspots in white light. SDO/HMI continuum intensitygram.",
            provider: "NASA SDO"
        ),
        .init(
            url: URL(string: "\(sdoBase)/latest_512_HMIB.jpg")!,
            label: "Magnetogram",
            caption: "Surface magnetic polarity. Black = north, white = south.",
            provider: "NASA SDO"
        ),
        .init(
            url: URL(string: "\(sdoBase)/latest_512_0304.jpg")!,
            label: "AIA 304 Å",
            caption: "Chromosphere and transition region (~50,000 K).",
            provider: "NASA SDO"
        ),
        .init(
            url: URL(string: "\(sdoBase)/latest_512_0171.jpg")!,
            label: "AIA 171 Å",
            caption: "Quiet corona and upper transition region (~1,000,000 K).",
            provider: "NASA SDO"
        ),
        .init(
            url: URL(string: "\(sdoBase)/latest_512_0193.jpg")!,
            label: "AIA 193 Å",
            caption: "Corona and hot flare plasma (~1.2-20 million K).",
            provider: "NASA SDO"
        ),
        .init(
            url: URL(string: "\(sdoBase)/latest_512_0094.jpg")!,
            label: "AIA 94 Å",
            caption: "Flaring regions, hot iron-XVIII plasma (~6 million K).",
            provider: "NASA SDO"
        ),
        .init(
            url: URL(string: "\(suviBase)/304/latest.png")!,
            label: "SUVI 304 Å",
            caption: "Same chromosphere band as SDO, from GOES-19.",
            provider: "NOAA SWPC / GOES"
        ),
        .init(
            url: URL(string: "\(suviBase)/171/latest.png")!,
            label: "SUVI 171 Å",
            caption: "Coronal loops from GOES-19's geosynchronous vantage.",
            provider: "NOAA SWPC / GOES"
        ),
        .init(
            url: URL(string: "\(lascoBase)/lasco-c2/latest.jpg")!,
            label: "LASCO C2",
            caption: "Inner coronagraph. CMEs visible against an occulted sun.",
            provider: "NASA/ESA SOHO"
        ),
        .init(
            url: URL(string: "\(lascoBase)/lasco-c3/latest.jpg")!,
            label: "LASCO C3",
            caption: "Wide-field coronagraph. Tracks CMEs out to 32 solar radii.",
            provider: "NASA/ESA SOHO"
        ),
    ]
}

/// NOAA SWPC OVATION aurora forecast. Two hemispheres, updated every
/// ~30 minutes. Oval-projection PNGs over an Earth basemap.
enum AuroraCatalog {
    static let northern = SunImageSource(
        url: URL(string: "https://services.swpc.noaa.gov/images/aurora-forecast-northern-hemisphere.jpg")!,
        label: "North",
        caption: "30-min aurora forecast, northern hemisphere oval projection.",
        provider: "NOAA SWPC OVATION"
    )
    static let southern = SunImageSource(
        url: URL(string: "https://services.swpc.noaa.gov/images/aurora-forecast-southern-hemisphere.jpg")!,
        label: "South",
        caption: "30-min aurora forecast, southern hemisphere oval projection.",
        provider: "NOAA SWPC OVATION"
    )
    static let both: [SunImageSource] = [northern, southern]
}

/// Curated deep-sky images from STScI press releases (Hubble + JWST).
/// Stable hot-link URLs published with the public-image releases.
enum DeepSkyCatalog {
    static let all: [SunImageSource] = [
        .init(
            url: URL(string: "https://stsci-opo.org/STScI-01EVT3VWZS3X74YN1KMBPS4PCM.png")!,
            label: "Carina Nebula",
            caption: "JWST NIRCam first-light cliffs of NGC 3324. 7,600 light-years away.",
            provider: "NASA / ESA / CSA STScI"
        ),
        .init(
            url: URL(string: "https://stsci-opo.org/STScI-01G7DDCYJ8HFBNTQVSXP3PT8VC.png")!,
            label: "Stephan's Quintet",
            caption: "JWST view of five galaxies, four in gravitational interaction.",
            provider: "NASA / ESA / CSA STScI"
        ),
        .init(
            url: URL(string: "https://stsci-opo.org/STScI-01G8H1NK4W8CJYHF2DDFD1W0DQ.png")!,
            label: "Southern Ring Nebula",
            caption: "JWST composite of NGC 3132, a dying star's shell.",
            provider: "NASA / ESA / CSA STScI"
        ),
        .init(
            url: URL(string: "https://stsci-opo.org/STScI-01EVSTBAFXAYAKGT7C13W7QSBS.png")!,
            label: "Pillars of Creation",
            caption: "Hubble's iconic Eagle Nebula stellar nursery (M16).",
            provider: "NASA / ESA STScI"
        ),
    ]
}
