require 'rails_helper'

RSpec.describe PublicEventsController, type: :controller do
  let(:venue) { create(:venue) }
  let(:creator) { create(:user) }
  
  let(:public_event) do
    create(:event, 
           venue: venue, 
           creator: creator,
           slug: 'test-event-2026',
           public_rsvp_enabled: true)
  end
  
  let(:private_event) do
    create(:event, 
           venue: venue, 
           creator: creator,
           slug: 'private-event-2026',
           public_rsvp_enabled: false)
  end

  describe 'GET #show' do
    context 'when event has public RSVP enabled' do
      it 'displays the public event page' do
        get :show, params: { slug: public_event.slug }
        expect(response).to have_http_status(:success)
        expect(assigns(:event)).to eq(public_event)
      end
    end

    context 'when event does not have public RSVP enabled' do
      it 'redirects to root with alert' do
        get :show, params: { slug: private_event.slug }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('This event does not accept public RSVPs.')
      end
    end

    context 'when event does not exist' do
      it 'redirects to root with alert' do
        get :show, params: { slug: 'nonexistent-event' }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Event not found.')
      end
    end
  end

  describe 'POST #rsvp' do
    context 'guest RSVP (not logged in)' do
      it 'creates a new guest RSVP' do
        expect {
          post :rsvp, params: {
            slug: public_event.slug,
            event_participant: {
              guest_name: 'John Doe',
              guest_email: 'john@example.com',
              rsvp_status: 'yes'
            }
          }
        }.to change(EventParticipant, :count).by(1)

        participant = EventParticipant.last
        expect(participant.guest_name).to eq('John Doe')
        expect(participant.guest_email).to eq('john@example.com')
        expect(participant.is_guest).to be true
        expect(participant.user_id).to be_nil
      end

      it 'redirects to confirmation page' do
        post :rsvp, params: {
          slug: public_event.slug,
          event_participant: {
            guest_name: 'John Doe',
            rsvp_status: 'yes'
          }
        }

        expect(response).to redirect_to(public_event_confirmation_path(public_event.slug, participant_id: EventParticipant.last.id))
      end
    end

    context 'invalid guest RSVP (render path)' do
      # render_views is load-bearing here: the failure path re-renders :show,
      # and the template needs @vendor_events — without rendering, a missing
      # ivar passes the spec but 500s in production.
      render_views

      it 'renders show with a visible alert and 422' do
        expect {
          post :rsvp, params: {
            slug: public_event.slug,
            event_participant: {
              guest_name: '',
              rsvp_status: 'yes'
            }
          }
        }.not_to change(EventParticipant, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq('Unable to save RSVP. Please check the form.')
      end
    end

    context 'RSVP rules enforcement (B2)' do
      it 'rejects a POST after the RSVP deadline' do
        closed_event = create(:event,
                              venue: venue,
                              creator: creator,
                              slug: 'closed-event-2026',
                              public_rsvp_enabled: true,
                              rsvp_deadline: 1.day.ago)

        expect {
          post :rsvp, params: {
            slug: closed_event.slug,
            event_participant: { guest_name: 'Late Larry', rsvp_status: 'yes' }
          }
        }.not_to change(EventParticipant, :count)

        expect(response).to redirect_to(public_event_path(closed_event.slug))
        expect(flash[:alert]).to eq('The RSVP deadline for this event has passed.')
      end

      it 'rejects a new "yes" when the event is at capacity' do
        full_event = create(:event,
                            venue: venue,
                            creator: creator,
                            slug: 'full-event-2026',
                            public_rsvp_enabled: true,
                            max_attendees: 1)
        create(:event_participant, event: full_event, guest_name: 'First Guest',
                                   is_guest: true, user: nil, rsvp_status: 'yes')

        expect {
          post :rsvp, params: {
            slug: full_event.slug,
            event_participant: { guest_name: 'Second Guest', rsvp_status: 'yes' }
          }
        }.not_to change(EventParticipant, :count)

        expect(response).to redirect_to(public_event_path(full_event.slug))
        expect(flash[:alert]).to eq('This event is at capacity.')
      end
    end

    context 'logged in user RSVP' do
      let(:user) { create(:user) }

      before { sign_in user }

      it 'creates RSVP associated with user' do
        expect {
          post :rsvp, params: {
            slug: public_event.slug,
            event_participant: {
              rsvp_status: 'yes'
            }
          }
        }.to change(EventParticipant, :count).by(1)

        participant = EventParticipant.last
        expect(participant.user).to eq(user)
        expect(participant.is_guest).to be false
      end

      it 'updates existing RSVP instead of creating duplicate' do
        existing = create(:event_participant, event: public_event, user: user, rsvp_status: 'maybe')

        expect {
          post :rsvp, params: {
            slug: public_event.slug,
            event_participant: {
              rsvp_status: 'yes'
            }
          }
        }.not_to change(EventParticipant, :count)

        existing.reload
        expect(existing.rsvp_status).to eq('yes')
      end
    end
  end

  describe 'GET #confirmation' do
    let!(:participant) { create(:event_participant, event: public_event, guest_name: 'Jane Doe', is_guest: true) }

    it 'displays confirmation page' do
      session[:confirmed_rsvp_ids] = [participant.id]
      get :confirmation, params: { slug: public_event.slug, participant_id: participant.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:event_participant)).to eq(participant)
    end

    it 'redirects if participant not found' do
      get :confirmation, params: { slug: public_event.slug, participant_id: 99999 }
      expect(response).to redirect_to(public_event_path(public_event.slug))
      expect(flash[:alert]).to eq('RSVP not found.')
    end
  end

  describe 'GET #calendar' do
    it 'generates .ics file for download' do
      get :calendar, params: { slug: public_event.slug }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/calendar')
      expect(response.headers['Content-Disposition']).to include('.ics')
    end
  end
end
