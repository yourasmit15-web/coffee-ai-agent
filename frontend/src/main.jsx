import React, { useEffect, useState } from 'react'
import { createRoot } from 'react-dom/client'
import './styles.css'

const API = import.meta.env.VITE_ADK_API_URL || 'http://localhost:8080'
function App(){
 const [messages,setMessages]=useState([{role:'assistant',text:'Hi! I’m Coffee AI. Tell me what kind of coffee you’re in the mood for.'}]);
 const [input,setInput]=useState(''); const [session,setSession]=useState(null); const [busy,setBusy]=useState(false);
 useEffect(()=>{fetch(`${API}/apps/coffee_agent/users/demo/sessions/demo`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}).then(r=>r.json()).then(setSession).catch(()=>{});},[])
 async function send(text=input){ if(!text.trim()||busy)return; setInput(''); setMessages(m=>[...m,{role:'user',text}]); setBusy(true); try{const r=await fetch(`${API}/run`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({appName:'coffee_agent',userId:'demo',sessionId:session?.id||'demo',newMessage:{role:'user',parts:[{text}]}})}); const data=await r.json(); const parts=Array.isArray(data)?data.flatMap(x=>x.content?.parts||[]):data.content?.parts||[]; const answer=parts.map(p=>p.text||'').filter(Boolean).join('\n')||'I could not generate a response.'; setMessages(m=>[...m,{role:'assistant',text:answer}]);}catch(e){setMessages(m=>[...m,{role:'assistant',text:'Backend connection failed. Start the ADK server on port 8080.'}])}finally{setBusy(false)}}
 return <main><section className="card"><header><div className="cup">☕</div><div><h1>Coffee AI</h1><p>Personalized coffee concierge</p></div></header><div className="chips">{['Recommend something for me','What is under ₹200?','I want something cold','Make an order draft'].map(x=><button onClick={()=>send(x)}>{x}</button>)}</div><div className="chat">{messages.map((m,i)=><div className={m.role==='user'?'msg user':'msg'} key={i}>{m.text}</div>)}{busy&&<div className="msg">Thinking…</div>}</div><form onSubmit={e=>{e.preventDefault();send()}}><input value={input} onChange={e=>setInput(e.target.value)} placeholder="Ask about coffee…"/><button>Send</button></form></section></main>}
createRoot(document.getElementById('root')).render(<App />)
