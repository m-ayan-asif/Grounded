const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/api/test', (req, res) => {
  res.json({ status: 'Server is running!' });
});

app.post('/api/breakdown', async (req, res) => {
  const { task, description } = req.body;

  const prompt = `Break down this task into 3-5 small, actionable subtasks with estimated time (e.g. "30min", "1hr"). Reply with ONLY a valid JSON array. No markdown, no code fences, no explanation. Example format: [{"title":"Do X","estimatedTime":"20min"}]

Task: ${task}
Description: ${description || "None"}`;

  try {
    const response = await fetch('http://localhost:11434/api/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
      model: 'gemma3:1b',  // <-- Changed from 'mistral'
      prompt: prompt,
      stream: false,
      }),
    });

    const data = await response.json();
    const text = data.response;

    // Extract JSON from response
    const jsonMatch = text.match(/\[[\s\S]*\]/);
    if (!jsonMatch) {
      return res.status(400).json({ error: 'No JSON found in response' });
    }

    const subtasks = JSON.parse(jsonMatch[0]);
    res.json({ subtasks });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, '0.0.0.0', () => {
  console.log('Backend running on http://localhost:3000');
});