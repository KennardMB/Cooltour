import Foundation
import Testing
import UIKit

@testable import Walkaby

@Suite("Content Pack Integrity Tests")
struct ContentPackIntegrityTests {

  private func loadPack(named name: String) throws -> ContentPack {
    let candidateBundles = [Bundle.main, Bundle(for: DummyTestAnchor.self)]
    for bundle in candidateBundles {
      if let pack = try? ContentPack.bundled(named: name, in: bundle) {
        return pack
      }
    }
    return try ContentPack.bundled(named: name)
  }

  @Test func renonContentPackDecodesAndLoadsAllSites() throws {
    let pack = try loadPack(named: "renon")
    #expect(pack.region == "Renon")
    #expect(pack.sites.count == 7)

    for site in pack.sites {
      #expect(!site.slug.isEmpty)
      #expect(!site.name.isEmpty)
      #expect(site.imageFile != nil)
      #expect(!site.imageFile!.isEmpty)
      #expect(site.imageSource != nil)
      #expect(!site.imageSource!.isEmpty)
      #expect(site.imageSource!.hasPrefix("http"))
      #expect(!site.stories.isEmpty)

      for story in site.stories {
        #expect(!story.slug.isEmpty)
        #expect(!story.audioFile.en.isEmpty)
        #expect(story.audioFile.id != nil && !story.audioFile.id!.isEmpty)
        #expect(!story.transcript.en.isEmpty)
        #expect(story.transcript.id != nil && !story.transcript.id!.isEmpty)
        #expect(story.durationSeconds.en > 0)
        #expect((story.durationSeconds.id ?? 0) > 0)
      }
    }
  }

  @Test func sanurContentPackDecodesAndLoadsAllSites() throws {
    let pack = try loadPack(named: "sanur")
    #expect(pack.region == "Sanur")
    #expect(pack.sites.count == 8)

    for site in pack.sites {
      #expect(!site.slug.isEmpty)
      #expect(!site.name.isEmpty)
      #expect(site.imageFile != nil)
      #expect(!site.imageFile!.isEmpty)
      #expect(site.imageSource != nil)
      #expect(!site.imageSource!.isEmpty)
      #expect(site.imageSource!.hasPrefix("http"))
      #expect(!site.stories.isEmpty)

      for story in site.stories {
        #expect(!story.slug.isEmpty)
        #expect(!story.audioFile.en.isEmpty)
        #expect(story.audioFile.id != nil && !story.audioFile.id!.isEmpty)
        #expect(!story.transcript.en.isEmpty)
        #expect(story.transcript.id != nil && !story.transcript.id!.isEmpty)
        #expect(story.durationSeconds.en > 0)
        #expect((story.durationSeconds.id ?? 0) > 0)
      }
    }
  }

  @Test func allAudioAndImageAssetsResolveInBundle() throws {
    let candidateBundles = [Bundle.main, Bundle(for: DummyTestAnchor.self)]

    for packName in ["renon", "sanur"] {
      let pack = try loadPack(named: packName)

      for site in pack.sites {
        // Verify image resolves in at least one bundle
        let imageFound = candidateBundles.contains { bundle in
          AssetResolver.siteImage(named: site.imageFile, bundle: bundle) != nil
        }
        #expect(imageFound, "Site image \(site.imageFile ?? "nil") not found for site \(site.slug)")

        for story in site.stories {
          // Verify EN audio resolves
          let enAudioFound = candidateBundles.contains { bundle in
            AssetResolver.audioURL(named: story.audioFile.en, bundle: bundle) != nil
          }
          #expect(enAudioFound, "EN audio \(story.audioFile.en) not found for story \(story.slug)")

          // Verify ID audio resolves
          if let idAudio = story.audioFile.id {
            let idAudioFound = candidateBundles.contains { bundle in
              AssetResolver.audioURL(named: idAudio, bundle: bundle) != nil
            }
            #expect(idAudioFound, "ID audio \(idAudio) not found for story \(story.slug)")
          }
        }
      }
    }
  }

  @Test func storyLanguageResolutionForRenonAndSanur() throws {
    for packName in ["renon", "sanur"] {
      let pack = try loadPack(named: packName)
      for siteData in pack.sites {
        for storyData in siteData.stories {
          let story = Story(
            slug: storyData.slug,
            title: storyData.title,
            audioAssetName: storyData.audioFile.en,
            audioAssetNameIndonesian: storyData.audioFile.id,
            transcript: storyData.transcript.en,
            transcriptIndonesian: storyData.transcript.id,
            durationSeconds: storyData.durationSeconds.en,
            durationSecondsIndonesian: storyData.durationSeconds.id
          )

          #expect(story.audioAssetName(for: .english) == storyData.audioFile.en)
          #expect(story.audioAssetName(for: .indonesian) == storyData.audioFile.id)
          #expect(story.transcript(for: .english) == storyData.transcript.en)
          #expect(story.transcript(for: .indonesian) == storyData.transcript.id)
          #expect(story.durationSeconds(for: .english) == storyData.durationSeconds.en)
          #expect(story.durationSeconds(for: .indonesian) == storyData.durationSeconds.id)
        }
      }
    }
  }

  @Test func appIconResolvesForMediaArtwork() {
    let candidateBundles = [Bundle.main, Bundle(for: DummyTestAnchor.self)]
    let appIconFound = candidateBundles.contains { bundle in
      AssetResolver.appIconImage(bundle: bundle) != nil
    }
    #expect(appIconFound, "App icon image should resolve for media player artwork")
  }
}

/// Anchor class to locate the test / host bundle
private final class DummyTestAnchor {}
