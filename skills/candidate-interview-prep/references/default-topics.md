# Default interview topics

Topics to include in every interview, in addition to whatever the job description and the user's prompt call for. Interviews are for software engineering roles unless the user says otherwise. Edit this file to change the defaults.

Each topic says what it's meant to reveal. Write the questions yourself, tied to the candidate's experience; the example angles are just starting points.

## Engineering topics

### 1. Core platform development (WordPress/PHP for WordPress roles; the role's main stack otherwise)
Reveals: whether they understand how the platform works rather than just using it.
Example angles: how they'd structure a plugin that has to coexist with unknown other plugins and themes; extending vs. modifying core or third-party code; hooks/actions/filters as a design tool; security habits (escaping, sanitizing, nonces, capabilities) explained through a real situation; a time a plugin/theme conflict bit them and how they found it.

### 2. Testing and quality
Reveals: whether they treat testing as part of the work or an afterthought, and how they decide what's worth testing.
Example angles: how they'd add tests to an untested legacy plugin; unit vs. integration vs. end-to-end trade-offs; what they'd test first in a project from their resume; how they keep a regression from coming back; code review habits; CI.

### 3. AI in their development work
Reveals: practical, critical use of AI tools, not hype or refusal.
Example angles: how they use AI assistants day to day and where they don't trust them; how they verify AI-generated code; a time an AI tool led them astray; how they'd use AI features inside a product (e.g. an LLM feature in a plugin) and the risks (cost, latency, privacy, prompt injection).

### 4. Thinking beyond the main stack
Reveals: breadth and the ability to pick the right tool, so they aren't someone who only knows one hammer.
Example angles: other languages, frameworks or paradigms they've used and what they took from them; when WordPress/PHP is the wrong choice; JavaScript/React (block editor), APIs, CLI tooling, infrastructure; how they'd learn an unfamiliar stack quickly.

### 5. Advanced: performance, databases and scaling
Reveals: diagnostic method under pressure, and depth with real systems.
Example angles: a page that got slow: how they'd find out why (profiling, query monitoring, slow query log, EXPLAIN) before touching anything; indexes and why `meta_query`/`postmeta` lookups get slow at scale; caching layers (object cache, page cache, CDN, transients) and invalidation; handling a 10x-50x traffic spike, and what breaks first as load grows (PHP workers, DB connections, locks, cache stampedes); read vs. write scaling (replicas, sharding, queues); measuring before and after (APM, load testing, budgets); trade-offs between optimizing code and adding infrastructure; background jobs/queues for heavy work; a scaling or performance problem from their own resume.

### 6. Debugging and problem solving
Reveals: how they work through an unknown problem.
Example angles: "a bug only happens in production for some users" scenario; the hardest bug they've fixed (dig into how they found it, not the fix); how they decide when to ask for help.

### 7. Collaboration and ownership
Reveals: how they work with a team, take feedback, and handle ambiguity.
Example angles: a disagreement in code review; working from an unclear ticket; supporting code they shipped after release; mentoring or being mentored (weight by seniority).

## When the user says the role isn't engineering

Use none of the topics above. Use topics from the job description and the user's prompt, plus "problem solving" and "collaboration and ownership" topics adapted to the role. Note that the interviewer is an engineer: if the role is outside their expertise, say so in the report, and give fuller "Listen for" notes so they can judge answers without domain knowledge.
