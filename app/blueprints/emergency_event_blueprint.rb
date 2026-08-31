class EmergencyEventBlueprint < Blueprinter::Base
  identifier :id
  fields :event_type, :sub_type, :notes, :resolved_at, :created_at

  field :latitude  do |e| e.latitude&.to_f  end
  field :longitude do |e| e.longitude&.to_f end

  field :user do |e|
    { id: e.user.id, name: e.user.name, username: e.user.username }
  end

  field :resolved_by do |e|
    e.resolved_by ? { id: e.resolved_by.id, name: e.resolved_by.name } : nil
  end
end
