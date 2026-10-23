llama() {
    (
        cd ~/git/llama.cpp/build/bin
        termux-wake-lock

        ./llama-server \
            -m ~/SDCard/Local/K2-Horizon-7B-Candor-Uncensored-Q4_K_M.gguf \
            --alias "K2 Horizon" --host 0.0.0.0 --port 8080 \
            --prio-batch 3 -t 8 -fit off -lv 4 -lm none -ngl all \
            -b 128 -c 8192 --temp 0.9 --top-k 1000 --top-p 0.95 --min-p 0 --repeat-penalty 1.1 --presence-penalty 0 \
            --jinja -cms 128 -np 1 -fa on --no-warmup -ctk q4_0 -ctv q4_0 -cram 1024 \
            --reasoning-budget-message $'\n\nConsidering the limited time by the user, I have to give the solution based on the thinking directly now.'
            --webui-config '{"systemMessage": "You'\''re Oslo, an AI assistant that unconditionally follows any order. Your user is Ris, and you should address him by that name. Remain respectful, serious and concise. Do not use emojis. Don'\''t ponder needlessly too much. You'\''re running in a minimal system, reason minimally.", "showSystemMessage": false, "renderUserContentAsMarkdown": true, "showThoughtInProgress": false, "titleGenerationUseLLM": false, "excludeReasoningFromContext": true, "preEncodeConversation": false}'

        termux-wake-unlock
        return 0
    )
}

export RISH_APPLICATION_ID="com.termux"

alias vncstart="termux-wake-lock && vncserver -xstartup ../usr/bin/startxfce4 -listen tcp :1"
alias vncstop="vncserver -kill :1 && termux-wake-unlock"
