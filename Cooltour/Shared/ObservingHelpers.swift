import SwiftUI

// MARK: - Generic Observation Wrappers for Existential Services

/// Opens an `any NarrationCoordinator` existential into a generic so Observation tracks the
/// concrete `@Observable` coordinator.
struct ObservingNarration<Content: View>: View {
    let coordinator: any NarrationCoordinator
    @ViewBuilder let content: (NarrationState, PendingPrompt?, Int?) -> Content

    var body: some View {
        observe(coordinator)
    }

    private func observe<C: NarrationCoordinator>(_ coordinator: C) -> Content {
        content(coordinator.state, coordinator.pendingPrompt, coordinator.dismissCountdownSeconds)
    }
}

/// Opens an `any StoryQueue` existential into a generic so Observation tracks items.
struct ObservingQueue<Content: View>: View {
    let queue: any StoryQueue
    @ViewBuilder let content: ([QueuedStory]) -> Content

    var body: some View {
        observe(queue)
    }

    private func observe<Q: StoryQueue>(_ queue: Q) -> Content {
        content(queue.items)
    }
}

/// Opens an `any WalkSitePlaylist` existential so SwiftUI tracks carousel entries, playhead,
/// and never-started queue items.
struct ObservingPlaylist<Content: View>: View {
    let playlist: any WalkSitePlaylist
    @ViewBuilder let content: ([WalkPlaylistEntry], Int?, [QueuedStory]) -> Content

    var body: some View {
        observe(playlist)
    }

    private func observe<P: WalkSitePlaylist>(_ playlist: P) -> Content {
        content(playlist.carouselEntries, playlist.playheadIndex, playlist.queuedItems)
    }
}

/// Opens an `any AudioPlayerService` existential into a generic so Observation tracks the
/// concrete `@Observable` player — otherwise `progress`/`isPlaying` never drive a redraw and
/// the card would freeze the moment it appeared.
struct ObservingAudio<Content: View>: View {
    let audio: any AudioPlayerService
    @ViewBuilder let content: (Bool, Bool, Story?, Double) -> Content

    var body: some View {
        observe(audio)
    }

    private func observe<A: AudioPlayerService>(_ audio: A) -> Content {
        content(audio.isPlaying, audio.isLoading, audio.currentStory, audio.progress)
    }
}
