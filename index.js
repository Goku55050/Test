const express = require('express');
const { Innertube } = require('youtubei.js');
const app = express();
const PORT = process.env.PORT || 5000;

let yt;

// Initialize Innertube (YouTube Internal API)
async function initYT() {
    try {
        yt = await Innertube.create();
        console.log("Ares Engine: Innertube Initialized ✅");
    } catch (err) {
        console.error("Initialization Failed ❌:", err.message);
    }
}

initYT();

app.get('/', (req, res) => {
    res.json({ status: "ARES NODE V9 ONLINE", owner: "Axer" });
});

app.get('/api/play', async (req, res) => {
    const query = req.query.q;
    if (!query) return res.status(400).json({ success: false, error: 'Bhai, query toh daal!' });

    try {
        if (!yt) await initYT();

        // Step 1: Search for the video
        const search = await yt.search(query, { type: 'video' });
        
        if (!search.videos || search.videos.length === 0) {
            return res.status(404).json({ success: false, error: 'Gaana nahi mila bhai.' });
        }

        const video = search.videos[0];
        const videoId = video.id;
        const title = video.title.text;

        // Step 2: Get Stream Info
        const info = await yt.getInfo(videoId);
        
        // Sabse best audio quality nikalna (Roblox compatible)
        const format = info.chooseFormat({ 
            type: 'audio', 
            quality: 'best' 
        });

        if (!format || !format.url) {
            return res.status(500).json({ success: false, error: 'Direct link nahi mil paya.' });
        }

        res.json({
            success: true,
            title: title,
            stream_url: format.url, // Ye link Roblox me chalega
            video_id: videoId
        });

    } catch (err) {
        console.error("Error:", err.message);
        res.status(500).json({ 
            success: false, 
            error: "YouTube ne block kiya ya server busy hai.",
            details: err.message 
        });
    }
});

app.listen(PORT, () => {
    console.log(`Ares Node API is running on port ${PORT}`);
});
