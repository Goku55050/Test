const express = require("express");
const yts = require("yt-search");
const cors = require("cors");

const app = express();
app.use(cors());

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

    } catch {
        res.json({ error: "Search failed" });
    }
});

/* 🎵 STREAM (NO DOWNLOAD) */
app.get("/stream", async (req, res) => {
    try {
        let url = req.query.url;
        if (!url) return res.json({ error: "No URL" });

        url = url.replace("shorts/", "watch?v=");

        // using yt-dlp to fetch direct audio URL only
        const { exec } = require("child_process");

        exec(`python3 -m yt_dlp -f bestaudio -g "${url}"`, (err, stdout) => {
            if (err) return res.json({ error: "Stream failed" });

            const streamUrl = stdout.trim();

            res.json({
                stream: streamUrl
            });
        });

    } catch {
        res.json({ error: "Stream failed" });
    }
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log("Running on port " + PORT);
});
