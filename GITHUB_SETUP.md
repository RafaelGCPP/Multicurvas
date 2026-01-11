# 🚀 Guia: Subindo para GitHub

Seu projeto está pronto localmente! Siga esses passos para colocar no GitHub:

## Passo 1️⃣: Criar Repositório no GitHub

1. Acesse [github.com](https://github.com) e faça login
2. No canto superior direito, clique no ➕ e selecione **"New repository"**
3. Preencha:
   - **Repository name**: `Multicurvas`
   - **Description**: "Parser de expressões matemáticas em C com suporte a gráficos polares, retangulares e paramétricos"
   - **Visibilidade**: Public (para ser visto) ou Private (só você)
   - ❌ **NÃO** marque "Add a README", "Add .gitignore" ou "Add a license" (já temos!)
4. Clique em **"Create repository"**

## Passo 2️⃣: Conectar Repositório Local ao GitHub

Após criar, você verá uma tela com comandos. Execute no terminal:

```bash
cd /home/hlpp/work/Multicurvas

# Conectar o repositório local ao remoto
git remote add origin https://github.com/realtico/Multicurvas.git

# Verificar que conectou
git remote -v
```

**Deveria mostrar:**
```
origin  https://github.com/realtico/Multicurvas.git (fetch)
origin  https://github.com/realtico/Multicurvas.git (push)
```

## Passo 3️⃣: Fazer Push (Enviar para GitHub)

```bash
git branch -M main                    # Renomear master → main (padrão moderno)
git push -u origin main               # Enviar para GitHub
```

Vai pedir seu **Personal Access Token** (PAT) do GitHub:

### Como criar um Personal Access Token:

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Clique **"Generate new token"** → **"Generate new token (classic)"**
3. Preencha:
   - **Note**: "Multicurvas push"
   - **Expiration**: 30 days (ou escolha)
   - **Scopes**: Marque apenas ✅ `repo` (acesso completo a repos privados/públicos)
4. Clique **"Generate token"**
5. **COPIE o token** (só aparece uma vez!)

### Usar o Token para Push:

```bash
git push -u origin main
```

Quando pedir username:
- **Username**: `realtico`
- **Password**: Cole o **Personal Access Token** (não sua senha!)

## Passo 4️⃣: Verificar no GitHub

1. Acesse https://github.com/realtico/Multicurvas
2. Deve mostrar seus arquivos: `src/`, `include/`, `README.md`, `DOCUMENTATION.md`, etc.
3. Pronto! 🎉

---

## 📋 Resumo de Comandos Rápido

```bash
# Uma só vez:
git remote add origin https://github.com/realtico/Multicurvas.git
git branch -M main
git push -u origin main

# Daqui pra frente, para enviar novos commits:
git push
```

---

## ⚠️ Troubleshooting

### "fatal: Could not read from remote repository"
- Verifique se o URL está correto
- Teste: `git remote -v`

### "fatal: Authentication failed"
- Token expirou ou foi copiado errado
- Crie novo token e tente novamente

### "error: src refspec main does not match any"
- Faça commit primeiro: `git commit -m "Initial commit"`
- Depois: `git branch -M main && git push -u origin main`

---

## 📚 Próximos Passos Opcionais

Após push, você pode:
1. ✅ Adicionar **Issues** para rastrear tarefas (Fase 2, 3, 4)
2. ✅ Adicionar **Collaborators** se quiser trabalhar em equipe
3. ✅ Ativar **Discussions** para perguntas/ideias
4. ✅ Configurar **GitHub Pages** para documentação (opcional)

---

**Pronto para subir? Siga os 4 passos acima! 🚀**
