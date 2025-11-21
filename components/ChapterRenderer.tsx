import CodeBlock from './CodeBlock'
import Link from 'next/link'
import fs from 'fs'
import path from 'path'

// Render mixed content (text + inline elements) with preserved document order
function renderMixedContent(children: any[], keyPrefix: string = '0'): React.ReactNode {
  if (!children || !Array.isArray(children)) return null
  
  return children.map((child, idx) => {
    const key = `${keyPrefix}-${idx}`
    
    // Plain text node
    if (child['#name'] === '__text__') {
      return child._ || ''
    }
    
    // Inline code
    if (child['#name'] === 'literal') {
      return (
        <code key={key} className="bg-base-300 text-base-content px-1.5 py-0.5 rounded font-mono text-sm">
          {child._ || ''}
        </code>
      )
    }
    
    // Emphasis (bold/italic)
    if (child['#name'] === 'emphasis') {
      const role = child.$?.role
      const hasNested = child.$$ && child.$$.some((c: any) => c['#name'] === 'emphasis' || c['#name'] === 'link')
      
      if (hasNested) {
        // Nested emphasis (bold+italic) or emphasis with links
        const content = renderMixedContent(child.$$, `${key}-nested`)
        return role === 'strong' ? (
          <strong key={key} className="font-bold text-base-content italic">{content}</strong>
        ) : (
          <em key={key} className="italic">{content}</em>
        )
      } else {
        const text = child._ || renderMixedContent(child.$$, `${key}-inner`)
        return role === 'strong' ? (
          <strong key={key} className="font-bold text-base-content">{text}</strong>
        ) : (
          <em key={key} className="italic">{text}</em>
        )
      }
    }
    
    // Links
    if (child['#name'] === 'link') {
      const rawHref = child.$?.['xl:href'] ?? child.$?.href
      const href = typeof rawHref === 'string' ? rawHref : ''
      const text = child._ || ''

      const isInternal = href.endsWith('.xml') || href.endsWith('.adoc')
      const finalHref = isInternal ? `/chapters/${href.replace(/\.(xml|adoc)$/, '')}` : href || '#'

      return isInternal ? (
        <Link key={key} href={finalHref} className="link text-accent">
          {text}
        </Link>
      ) : (
        <a
          key={key}
          href={finalHref}
          className="link text-accent"
          target="_blank"
          rel="noopener noreferrer"
        >
          {text}
        </a>
      )
    }
    
    return null
  })
}

// Render a block-level element
function renderBlock(node: any, index: number): React.ReactNode {
  const name = node['#name']
  const children = node.$$
  const key = `block-${index}`
  
  // Paragraph
  if (name === 'simpara') {
    // Check for horizontal rule processing instruction
    if (node._ && node._.includes('asciidoc-hr')) {
      return <hr key={key} className="my-8 border-t-2 border-base-300" />
    }
    
    return (
      <p key={key} className="mb-6 leading-relaxed">
        {renderMixedContent(children, `para-${index}`)}
      </p>
    )
  }
  
  // Code block
  if (name === 'programlisting') {
    let codeText = node._ || ''
    const language = node.$?.language || 'text'
    
    // Handle unresolved includes - extract the file path and read it
    if (codeText.includes('Unresolved directive') && codeText.includes('include::')) {
      const match = codeText.match(/include::example\$chapters-data\/code\/([^[\]]+)/)
      if (match) {
        const filePath = match[1]
        const fullPath = path.join(process.cwd(), 'chapters-data', 'code', filePath)
        
        try {
          // Read the code file synchronously (safe in server components)
          codeText = fs.readFileSync(fullPath, 'utf-8')
        } catch (error) {
          return (
            <div key={key} className="alert alert-error my-4">
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <div>
                <div className="font-bold">Code file not found</div>
                <div className="text-sm">{filePath}</div>
              </div>
            </div>
          )
        }
      }
    }
    
    return <CodeBlock key={key} code={codeText} language={language} />
  }
  
  // Itemized list
  if (name === 'itemizedlist') {
    const items = children?.filter((c: any) => c['#name'] === 'listitem') || []
    return (
      <ul key={key} className="list-disc list-outside ml-6 mb-6 space-y-3">
        {items.map((item: any, i: number) => {
          const itemChildren = item.$$?.filter((c: any) => c['#name'] === 'simpara') || []
          return (
            <li key={i} className="text-base-content/90 pl-2">
              {itemChildren.map((p: any, j: number) => (
                <span key={j}>{renderMixedContent(p.$$, `list-${index}-${i}-${j}`)}</span>
              ))}
            </li>
          )
        })}
      </ul>
    )
  }
  
  // Ordered list
  if (name === 'orderedlist') {
    const items = children?.filter((c: any) => c['#name'] === 'listitem') || []
    const numeration = node.$?.numeration || 'arabic'
    const listStyle = numeration === 'loweralpha' ? 'list-[lower-alpha]' : 
                     numeration === 'upperalpha' ? 'list-[upper-alpha]' :
                     numeration === 'lowerroman' ? 'list-[lower-roman]' :
                     numeration === 'upperroman' ? 'list-[upper-roman]' : 'list-decimal'
    
    return (
      <ol key={key} className={`${listStyle} list-outside ml-6 mb-6 space-y-3`}>
        {items.map((item: any, i: number) => {
          return (
            <li key={i} className="text-base-content/90 pl-2">
              {item.$$?.map((child: any, j: number) => renderBlock(child, j))}
            </li>
          )
        })}
      </ol>
    )
  }
  
  // Variable list (definition list)
  if (name === 'variablelist') {
    const entries = children?.filter((c: any) => c['#name'] === 'varlistentry') || []
    return (
      <div key={key} className="mb-8">
        {entries.map((entry: any, i: number) => {
          const termNode = entry.$$?.find((c: any) => c['#name'] === 'term')
          const listitemNode = entry.$$?.find((c: any) => c['#name'] === 'listitem')
          
          return (
            <div key={i} className="mb-6">
              <dt className="font-bold text-lg mb-3 text-primary">
                {termNode?._  || ''}
              </dt>
              <dd className="ml-6">
                {listitemNode?.$$?.map((child: any, j: number) => renderBlock(child, j))}
              </dd>
            </div>
          )
        })}
      </div>
    )
  }
  
  // Block quote
  if (name === 'blockquote') {
    const paras = children?.filter((c: any) => c['#name'] === 'simpara') || []
    const attribution = children?.find((c: any) => c['#name'] === 'attribution')?._
    
    return (
      <blockquote
        key={key}
        className="prose-quote relative my-8 rounded-xl border border-base-300/60 border-l-4 border-l-accent/70 bg-base-200/60 px-5 py-4 italic shadow-sm transition-transform duration-150 ease-out hover:-translate-y-[2px] hover:shadow-[0_12px_30px_rgba(0,0,0,0.25)]"
      >
        {paras.map((p: any, i: number) => (
          <p key={i} className="mb-2 text-base-content/80">
            {renderMixedContent(p.$$, `quote-${index}-${i}`)}
          </p>
        ))}
        {attribution && (
          <footer className="mt-4 text-sm text-base-content/60 not-italic">
            — {attribution}
          </footer>
        )}
      </blockquote>
    )
  }
  
  // Formal paragraph (like "Run" or "Output" labels)
  if (name === 'formalpara') {
    const titleNode = children?.find((c: any) => c['#name'] === 'title')
    const paraNode = children?.find((c: any) => c['#name'] === 'para')
    
    return (
      <div key={key} className="my-6">
        <div className="badge badge-primary badge-lg mb-3">{titleNode?._ || ''}</div>
        {paraNode?.$$?.map((child: any, i: number) => renderBlock(child, i))}
      </div>
    )
  }
  
  // Admonitions (note, warning, tip, caution, important)
  if (['note', 'warning', 'tip', 'caution', 'important'].includes(name)) {
    const alertType = name === 'warning' || name === 'caution' ? 'alert-warning' :
                     name === 'important' ? 'alert-error' : 'alert-info'
    const icon = name === 'warning' || name === 'caution' ? (
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
    ) : name === 'tip' ? (
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
    ) : (
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    )
    
    return (
      <div
        key={key}
        className={`alert ${alertType} my-6 rounded-xl border border-base-300/60 shadow-sm`}
      >
        <svg className="h-6 w-6 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          {icon}
        </svg>
        <div className="flex-1 space-y-2 text-sm leading-relaxed">
          {children?.map((child: any, i: number) => renderBlock(child, i))}
        </div>
      </div>
    )
  }
  
  // Tables
  if (name === 'informaltable' || name === 'table') {
    const tgroup = children?.find((c: any) => c['#name'] === 'tgroup')
    if (!tgroup) return null
    
    const thead = tgroup.$$?.find((c: any) => c['#name'] === 'thead')
    const tbody = tgroup.$$?.find((c: any) => c['#name'] === 'tbody')
    const headerRows = thead?.$$?.filter((c: any) => c['#name'] === 'row') || []
    const bodyRows = tbody?.$$?.filter((c: any) => c['#name'] === 'row') || []
    
    return (
      <div key={key} className="my-6 overflow-x-auto">
        <table className="table table-zebra table-sm chapter-table">
          {headerRows.length > 0 && (
            <thead>
              {headerRows.map((row: any, i: number) => {
                const entries = row.$$?.filter((c: any) => c['#name'] === 'entry') || []
                return (
                  <tr key={i}>
                    {entries.map((entry: any, j: number) => {
                      // Entry might contain simpara or direct mixed content
                      const content = entry.$$?.find((c: any) => c['#name'] === 'simpara')
                      return (
                        <th key={j}>
                          {content ? renderMixedContent(content.$$, `th-${index}-${i}-${j}`) : renderMixedContent(entry.$$, `th-${index}-${i}-${j}`)}
                        </th>
                      )
                    })}
                  </tr>
                )
              })}
            </thead>
          )}
          <tbody>
            {bodyRows.map((row: any, i: number) => {
              const entries = row.$$?.filter((c: any) => c['#name'] === 'entry') || []
              return (
                <tr key={i}>
                  {entries.map((entry: any, j: number) => {
                    // Entry might contain simpara or direct mixed content
                    const content = entry.$$?.find((c: any) => c['#name'] === 'simpara')
                    return (
                      <td key={j}>
                        {content ? renderMixedContent(content.$$, `td-${index}-${i}-${j}`) : renderMixedContent(entry.$$, `td-${index}-${i}-${j}`)}
                      </td>
                    )
                  })}
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    )
  }
  
  // Screen/literal layout (preformatted text, not code)
  if (name === 'screen' || name === 'literallayout') {
    const text = node._ || ''
    
    // Check if this is a mermaid diagram (starts with graph/flowchart/sequenceDiagram/etc)
    const mermaidKeywords = ['graph ', 'flowchart ', 'sequenceDiagram', 'classDiagram', 'stateDiagram', 'erDiagram', 'gantt', 'pie', 'journey']
    const isMermaid = mermaidKeywords.some(keyword => text.trim().startsWith(keyword))
    
    if (isMermaid) {
      return (
        <div key={key} className="mermaid my-6 bg-base-100 p-4 rounded-lg border border-base-300 overflow-x-auto">
          {text}
        </div>
      )
    }
    
    return (
      <pre key={key} className="bg-base-200 p-4 rounded-lg overflow-x-auto my-4 text-sm">
        {text}
      </pre>
    )
  }
  
  // Sidebar (call-out boxes)
  if (name === 'sidebar') {
    const titleNode = children?.find((c: any) => c['#name'] === 'title')
    return (
      <aside key={key} className="bg-base-200 border-l-4 border-accent p-6 my-6 rounded-r-lg">
        {titleNode && (
          <h4 className="font-bold text-lg mb-3 text-accent">{titleNode._}</h4>
        )}
        <div className="prose prose-sm">
          {children?.filter((c: any) => c['#name'] !== 'title').map((child: any, i: number) => renderBlock(child, i))}
        </div>
      </aside>
    )
  }
  
  return null
}

// Render a section (chapter or subsection)
function renderSection(section: any, depth: number = 0): React.ReactNode {
  const children = section.$$ || []
  const id = section.$?.['xml:id'] || ''
  const title = children.find((c: any) => c['#name'] === 'title')?._  || ''
  
  const elements: React.ReactNode[] = []
  
  // Add title
  if (title) {
    if (depth === 0) {
      elements.push(
        <h2 key="title" id={id} className="prose-heading mt-12 mb-6 scroll-mt-24">
          {title}
        </h2>
      )
    } else {
      elements.push(
        <h3 key="title" id={id} className="prose-subheading mb-4 scroll-mt-24">
          {title}
        </h3>
      )
    }
  }
  
  // Render all children in order
  children.forEach((child: { [x: string]: any }, idx: number) => {
    const name = child['#name']
    
    if (name === 'title') {
      // Already handled
      return
    }
    
    if (name === 'section') {
      // Nested subsection
      elements.push(
        <div key={`section-${idx}`} className={depth === 0 ? 'mt-8 mb-6' : 'ml-4 mt-6'}>
          {renderSection(child, depth + 1)}
        </div>
      )
    } else {
      // Block content
      const rendered = renderBlock(child, idx)
      if (rendered) {
        elements.push(rendered)
      }
    }
  })
  
  return elements
}

export default function ChapterRendererV2({ content }: { content: any }) {
  if (!content || !content.chapters || content.chapters.length === 0) {
    return (
      <div className="alert alert-warning shadow-lg">
        <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
        </svg>
        <div>
          <h3 className="font-bold">Chapter Not Yet Available</h3>
          <div className="text-sm">This chapter hasn&apos;t been converted to XML yet.</div>
        </div>
      </div>
    )
  }

  return (
    <div className="chapter-content">
      {content.chapters.map((chapter: any, index: number) => (
        <section key={index} className="mb-16">
          {renderSection(chapter, 0)}
        </section>
      ))}
    </div>
  )
}
