const express = require("express");
const yts = require("yt-search");
const fs = require("fs");
const path = require("path");
const cors = require("cors");
const { exec } = require("child_process");

const app = express();
app.use(cors());

const MUSIC_DIR = path.join(__dirname, "music");

if (!fs.existsSync(MUSIC_DIR)) {
    fs.mkdirSync(MUSIC_DIR);
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
        res.json({ error: "Search failed" });
    }
});

/* 🎵 DOWNLOAD */
app.get("/download", async (req, res) => {
    try {
        let url = req.query.url;
        if (!url) return res.json({ error: "No URL" });

        url = url.replace("shorts/", "watch?v=");

        const id = Date.now();
        const filePath = path.join(MUSIC_DIR, id + ".mp3");

        const command = `yt-dlp -x --audio-format mp3 --no-playlist -o "${filePath}" "${url}"`;

        exec(command, (error) => {
            if (error) {
                console.log(error);
                return res.json({ error: "Download failed" });
            }

            res.json({
                audio: `/music/${id}.mp3`
            });
        });

    } catch (err) {
        res.json({ error: "Download failed" });
    }
});

/* 📁 SERVE FILE */
app.use("/music", express.static(MUSIC_DIR));

/* 🧹 AUTO DELETE */
setInterval(() => {
    const files = fs.readdirSync(MUSIC_DIR);

    files.forEach(file => {
        const filePath = path.join(MUSIC_DIR, file);
        const stats = fs.statSync(filePath);

        if (Date.now() - stats.mtimeMs > 1000 * 60 * 60) {
            fs.unlinkSync(filePath);
        }
    });
}, 600000);

/* 🚀 START */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log("Running on port " + PORT);
});
