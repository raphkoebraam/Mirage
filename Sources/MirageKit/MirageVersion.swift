public enum MirageVersion {
    /// Placeholder for development builds. The release workflow and
    /// `mise run build` overwrite it at build time from the git tag, so the
    /// tag is the only place a version is ever typed.
    public static let current = "0.0.0-dev"
}
