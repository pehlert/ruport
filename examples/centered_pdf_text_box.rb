require "ruport"                             
 
# Renderers can be though of as control classes or interface builders.
# Essentially, they define the options that formatters should implement
# and the stages of rendering they should handle.  Ruport's formatting
# system is very forgiving, and the renderers do not force their
# specs onto formatters that are attached to them. 
#
class Document < Ruport::Renderer
  
  # will throw an error if these options are not set at rendering time
  required_option :text, :author                                      
  
  # allows this option to be set directly on a renderer instance,
  # and creates a reader for it if a header() method does not already exist
  option :heading
  
  # The renderer will look for a build_document_body() method on the formatter,
  # but silently skip this stage if it is missing
  stage :document_body
  
  # The renderer will look for a finalize_document() method on the formatter,
  # but silently skip this stage if it is missing
  finalize :document                            
end
  
# Ruport's PDF Formatter has a large number of helpers that simplify some
# basic PDF operations.  For the things it misses, it also provides a 
# pdf_writer method that gives you direct access to the underlying PDF::Writer
# library.  If you frequently find yourself using that feature, you might
# consider taking a look at the pdf_writer_proxy plugin for Ruport.
#
# The helpers demonstrated here are add_text, center_image_in_box, 
# and render_text_box
#
class CenteredPDFTextBox < Ruport::Formatter::PDF

  renders :pdf, :for => Document

  def build_document_body
    add_text "-- " << options.author << " --",
             :justification => :center, :font_size => 20
    
    c = pdf_writer.absolute_x_middle - 239/2
    
    center_image_in_box("RWEmerson.jpg", :x     => c,        :y => 325,
                                         :width => 239, :height => 359)
 
    rounded_text_box(options.text) do |o|       
       o.x = pdf_writer.absolute_x_middle - o.width/2
       o.y = 300                          
       
       o.radius = 5
       o.width     = options.width  || 400
       o.height    = options.height || 130
       o.font_size = options.font_size || 12
       o.heading   = options.heading
    end
  end
  
  def finalize_document
    render_pdf
  end
end

# All options passed to a renderer will be written onto the options object.
# In the block form, you may use explicit accessors 
# (i.e. r.text instead of r.options.text ) for only things that have
# either been defined with option / required_option methods, 
# or have explicit accessors in the Renderer.
#
a = Document.render_pdf( :heading => "a good quote", 
                         :author => "Ralph Waldo Emerson") do |r|
  r.text = <<EOS
A foolish consistency is the hobgoblin of little minds, adored by little
statesmen and philosophers and divines. With consistency a great soul has simply
nothing to do. He may as well concern himself with his shadow on the wall. Speak
what you think now in hard words and to-morrow speak what to-morrow thinks in
hard words again, though it contradict every thing you said to-day.--"Ah, so you
shall be sure to be misunderstood."--Is it so bad then to be misunderstood?
Pythagoras was misunderstood, and Socrates, and Jesus, and Luther, and
Copernicus, and Galileo, and Newton, and every pure and wise spirit that ever
took flesh. To be great is to be misunderstood. . . .
EOS
end

puts a