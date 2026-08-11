🛡️ Automação de Auditoria de Permissões NTFS e Active Directory
Resumo do Projeto
Desenvolvimento de uma solução automatizada em PowerShell para auditoria de segurança e extração de permissões de acesso (NTFS) em diretórios de rede corporativos. O projeto foi criado para substituir o uso de softwares de terceiros com limitações de licenciamento (como a versão gratuita do NTFS Permissions Reporter), garantindo total autonomia, padronização e escalabilidade para o departamento de TI.

O Problema
Anteriormente, a auditoria de acessos às pastas de rede compartilhadas e aos diretórios dos departamentos exigia um esforço manual significativo. A ferramenta utilizada não permitia a exportação automatizada e estruturada na versão gratuita, e o processo de cruzar os grupos de segurança listados nas pastas com os seus respectivos usuários finais no Active Directory consumia horas de trabalho operacional da equipe de infraestrutura.

A Solução
Foi construído um script em PowerShell nativo que varre automaticamente todos os subdiretórios de uma unidade de rede (ex: departamentos da empresa) e extrai as Listas de Controle de Acesso (ACLs). O grande diferencial da ferramenta é a integração direta com as classes .NET do Windows, permitindo consultar o Active Directory e expandir grupos aninhados sem a necessidade de instalar módulos adicionais (RSAT).

Por fim, o script compila os dados, injeta em um template HTML estilizado com CSS corporativo e utiliza o motor do Microsoft Edge em segundo plano (headless mode) para gerar relatórios individuais em PDF.

Principais Funcionalidades (Features)

Varredura em Lote (Batch Scanning): Identifica e processa automaticamente dezenas de diretórios a partir de uma pasta raiz.

Resolução Nativa de AD: Expande grupos de segurança do domínio para listar os usuários finais reais, herdando acessos aninhados sem dependências externas.

Geração Automática de PDF: Conversão direta de dados brutos para documentos PDF formatados e prontos para impressão/envio.

Design Corporativo e Auditável: Relatórios gerados com cabeçalho institucional, metadados da extração e um bloco de assinaturas formal com prevenção de quebra de página (Controller e Gestor da Área).

Tratamento de Exceções: Lógica de tolerância a falhas que ignora contas órfãs, caminhos de rede inacessíveis e SIDs deletados sem interromper o processo global.

Tecnologias Utilizadas

Linguagem: PowerShell 5.1+

Bibliotecas: System.DirectoryServices.AccountManagement (C# / .NET)

Formatação: HTML5 e CSS3

Motor de Renderização: Microsoft Edge (Chromium Headless)

Impacto para o Negócio

Redução de Custos: Eliminação da necessidade de licenças pagas para softwares de auditoria de arquivos.

Ganho de Produtividade: Redução do tempo de extração de horas de trabalho manual para apenas alguns segundos de processamento automatizado.

Governança e Compliance: Geração de artefatos padronizados, imutáveis (PDF) e prontos para coleta de assinaturas, facilitando auditorias internas e externas (ex: ISO 27001, LGPD).
