package com.inschemes.app

import android.app.Activity
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

/** Streams Sarvam PCM without waiting for a complete MP3 or running another TTS. */
class PcmPlaybackBridge(activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "com.inschemes.app/voice_pcm")
    private val manager = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val generation = AtomicInteger(0)
    private class Playback(val track: AudioTrack, val rate: Int) {
        var frames = 0L
        var started = false
        fun play() { if (!started) { track.play(); started = true } }
    }
    @Volatile private var playback: Playback? = null
    private var focus: AudioFocusRequest? = null
    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    stop()
                    try {
                        val rate = call.argument<Int>("sampleRate") ?: 16000
                        require(rate == 8000 || rate == 16000 || rate == 22050)
                        val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
                        val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                            .setAudioAttributes(attributes).setOnAudioFocusChangeListener { change ->
                                if (change < 0) stop()
                            }.build()
                        if (manager.requestAudioFocus(request) != AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
                            throw IllegalStateException("Audio focus unavailable")
                        focus = request
                        val track = AudioTrack.Builder().setAudioAttributes(attributes)
                            .setAudioFormat(AudioFormat.Builder().setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                                .setSampleRate(rate).setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
                            .setBufferSizeInBytes(maxOf(AudioTrack.getMinBufferSize(rate,
                                AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT), rate))
                            .setTransferMode(AudioTrack.MODE_STREAM).build()
                        playback = Playback(track, rate)
                        result.success(null)
                    } catch (_: Exception) { stop(); result.error("AUDIO_UNAVAILABLE", "Playback unavailable", null) }
                }
                "write", "drain" -> {
                    val current = playback
                    val version = generation.get()
                    val bytes = call.arguments as? ByteArray
                    worker.execute {
                        try {
                            if (generation.get() == version && current != null) {
                                if (call.method == "write") {
                                    require(bytes != null && bytes.size <= 128000 && bytes.size % 2 == 0)
                                    var offset = 0
                                    while (offset < bytes.size && generation.get() == version) {
                                        val written = current.track.write(bytes, offset,
                                            minOf(bytes.size - offset, current.rate / 5), AudioTrack.WRITE_BLOCKING)
                                        if (written <= 0) throw IllegalStateException("Playback unavailable")
                                        offset += written
                                        current.frames += written / 2
                                        // A short prebuffer absorbs network jitter without long latency.
                                        if (current.frames >= current.rate * 3 / 10) current.play()
                                    }
                                } else {
                                    if (current.frames > 0) current.play()
                                    val deadline = System.currentTimeMillis() + 12000
                                    while (generation.get() == version &&
                                        (current.track.playbackHeadPosition.toLong() and 0xffffffffL) < current.frames) {
                                        if (System.currentTimeMillis() > deadline) throw IllegalStateException("Playback timeout")
                                        Thread.sleep(10)
                                    }
                                }
                            } else if (generation.get() == version) throw IllegalStateException("Playback unavailable")
                            main.post { result.success(null) }
                        } catch (_: Exception) {
                            main.post {
                                if (generation.get() == version) result.error("AUDIO_UNAVAILABLE", "Playback unavailable", null)
                                else result.success(null)
                            }
                        }
                    }
                }
                "stop" -> { stop(); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }
    private fun stop() {
        generation.incrementAndGet()
        val old = playback?.track
        playback = null
        try { old?.pause(); old?.flush(); old?.release() } catch (_: Exception) { }
        focus?.let { manager.abandonAudioFocusRequest(it) }
        focus = null
    }
    fun dispose() { channel.setMethodCallHandler(null); stop(); worker.shutdownNow() }
}
