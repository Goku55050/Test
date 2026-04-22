const express = require("express");
const yts = require("yt-search");
const fs = require("fs");
const path = require("path");
const cors = require("cors");
const { exec } = require("child_process");

const app = express();
app.use(cors());

// ✅ IMPORTANT: use /tmp for Render
const MUSIC_DIR = "/tmp/music";

// create folder safely
if (!fs.existsSync(MUSIC_DIR)) {
    fs.mkdirSync(MUSIC_DIR, { recursive: true });
}

/* 🔍 SEARCH */
app.get("/search", async (req, res) => {
    try {
        const query = req.query.q;
        if (!query) return res.json({ error: "No query" });

        const result = await yts(query);
        const video = result.videos[0];

        if (!video) return res.json({ error: "No results" });

        res.json({
            title: video.title,
            url: video.url,
            thumbnail: video.thumbnail,
            duration: video.timestamp
        });

    } catch (err) {
        console.log(err);
        res.json({ error: "Search failed" });
    }
});

/* 🎵 DOWNLOAD (FINAL FIXED) */
app.get("/download", async (req, res) => {
    try {
        let url = req.query.url;
        if (!url) return res.json({ error: "No URL" });

        // fix shorts
        url = url.replace("shorts/", "watch?v=");

        const id = Date.now();
        const outputTemplate = path.join(MUSIC_DIR, `${id}.%(ext)s`);

        const command = `python3 -m yt_dlp -x --audio-format mp3 --no-playlist -o "${outputTemplate}" "${url}"`;

        console.log("RUN:", command);

        exec(command, (error, stdout, stderr) => {
            console.log("STDOUT:", stdout);
            console.log("STDERR:", stderr);

            if (error) {
                console.log("ERROR:", error);
                return res.json({ error: "Download failed" });
            }

            // find actual file
            const files = fs.readdirSync(MUSIC_DIR);
            const file = files.find(f => f.startsWith(id));

            if (!file) {
                return res.json({ error: "File not found after download" });
            }

            res.json({
                audio: `/music/${file}`
            });
        });

    } catch (err) {
        console.log("SERVER ERROR:", err);
        res.json({ error: "Download failed" });
    }
});

/* 📁 SERVE FILES */
app.use("/music", express.static(MUSIC_DIR));

/* 🧹 AUTO DELETE (1 hour) */
setInterval(() => {
    try {
        const files = fs.readdirSync(MUSIC_DIR);

        files.forEach(file => {
            const filePath = path.join(MUSIC_DIR, file);
            const stats = fs.statSync(filePath);

            if (Date.now() - stats.mtimeMs > 1000 * 60 * 60) {
                fs.unlinkSync(filePath);
            }
        });
    } catch (err) {
        console.log("CLEANUP ERROR:", err);
    }
}, 600000);

/* 🚀 START */
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log("Server running on port " + PORT);
});
